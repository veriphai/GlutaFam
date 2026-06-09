# API Revamp Plan — Career-Discovery Homepage + Activities

**Status:** Proposal for review (no code changes yet).
**Scope:** Map every API surface the revamped app needs against the 83 existing
endpoints. List **keep / modify / new** with concrete request/response shapes,
plus the phone-OTP gap fix and cross-cutting fixes.

---

## 0. TL;DR

- **What exists is solid plumbing, wrong shape for careers.** The 83 endpoints are
  built around a *school curriculum* model (subjects, chapters, lessons, AI tutor,
  quests, daily quiz, friends/feed). None speak "professions / worlds / missions".
- **Auth + OTP both already work** (Firebase phone-auth + Google sign-in feed the
  same Firebase ID token to `POST /fam/auth`, which returns the app JWT). The
  phone-after-Google gap is a **flow change in the client + one new backend
  endpoint to mark phone as OTP-verified**, not a new OTP system.
- **Two real bugs in existing code** to fix while we're touching it:
  `fetchCheckpointFeedback` points at a LAN IP `192.168.165.204`, and there is
  **no centralized base URL** — every file hardcodes `https://glutaclass.com:8080/…`.
- **New career APIs needed: 12** (worlds, professions, current mission, mission
  config, mission progress + complete, daily challenge, passport, home aggregate,
  activity registry, phone verify, profile completeness, plus an avatar upload
  for kid avatars).
- **Everything new lives under the `howwow` namespace** — the new app is named
  **howwow**. Legacy `fam` segment is gone from the new paths.
- **Implementation reality:** the Spring backend (`saaraansh`) has a global
  context-path of `/gluta`, so the **actual URL** is
  `https://glutaclass.com:8080/gluta/howwow/...`. This matches how every
  existing product in the monorepo lives (`/gluta/fam/`, `/gluta/famV2/`,
  `/gluta/tutor/`). Throughout this doc, paths like `/howwow/auth/login`
  refer to the controller mapping; the full URL the client hits is
  `<host>/gluta/howwow/auth/login`. The `Endpoints.howwow(p)` helper in §7.1
  resolves this.
- **A dedicated `POST /howwow/auth/login`** replaces the implicit
  `/gluta/fam/auth?idToken=…` for the revamped flow — cleaner semantics, embeds
  the profile in the response (saves a round trip), still verifies the same
  Firebase ID token with the same Firebase Admin SDK config on the backend.
- **Four backend controllers** organize the new surface: `AuthController`,
  `ProfileController`, `CareerController`, `ActivityController` — see §10.

---

## 1. Today's state — what's already there

### 1.1 Backend topology
- One host: `https://glutaclass.com:8080`
- **New namespace for the revamp: `/howwow/…`** (everything in §2–§4 lives here).
- Existing path families (left as-is for the legacy curriculum surfaces):
  - `/gluta/fam/…` — legacy v1: **auth, profile, add-profile, log-event, submit-feedback, save-checkpoint, save-referral-link, save-learning-gap**
  - `/gluta/famV2/…` — current bulk: lessons, quizzes, achievements, powerups, leaderboard, friends, feed, quests, schools/states/cities, languages, FCM token, …
  - `/gluta/tutor/…` — AI tutor: `responseV2`, `gap-resolution`, `lesson-history`, `recommended-lessons`, `today-concepts`, `checkpoint-feedback`, `retry`
  - `/gluta/api/…` — newer-style: `journeys`, `tasks/:id/status`

### 1.2 Auth flow today (works — extend, don't replace)
```
                        ┌────────────────────────────────────────────┐
   PhoneEntry  ──(SMS)─►│ FirebaseAuth.verifyPhoneNumber             │
   OR Google sign-in ──►│ → returns Firebase credential              │
                        └───────────────────┬────────────────────────┘
                                            │  signInWithCredential
                                            ▼
                                FirebaseAuth.currentUser → user.getIdToken()
                                            │ stored as "IdToken" in secure storage
                                            ▼
   POST /gluta/fam/auth?idToken=<firebase id token>
                                            │
                                            ▼
   { token: <appJWT>, newUser: bool, userTrackingId: <id>, … }
                                            │ token stored as "authKey"
                                            ▼
   newUser → OnboardingScreenV4    /    existing → MainPage
```
- **Every subsequent API call** uses `Authorization: Bearer <authKey>`.
- Phone OTP is **Firebase-side, not our backend**. We never send SMS ourselves.
- `loginScreen.dart` does Google sign-in; `signupScreen.dart` → `otpPage.dart`
  does phone+OTP. Both end at the same `sendIdTokenToBackend()` call.

### 1.3 Profile
- `GET /gluta/fam/profile` (Bearer) — returns the user profile object.
- `POST /gluta/fam/profile` (Bearer) — accepts an arbitrary `Map<String,dynamic>`
  and persists it. Schema is **not enforced client-side**; the backend decides.
- `POST /gluta/fam/add-profile` — used **only** from `signupScreen.dart` for
  first-create. Should be **merged with `POST /profile`** to remove ambiguity.
- Fields read by the client (inferred from usage): `firstName`, `emailId`,
  `photoUrl`, `phoneNumber`, `standard`, `schoolId`, `stateId`, `cityId`,
  `dob`, `gender`, `avatarId`, `credits`, `streak`, plus the tracked
  `userTrackingId`. **Phone is currently a free-text field, not OTP-bonded.**

### 1.4 Content surface (the 83 endpoints, grouped)

| Group | Endpoints | Re-usability for revamp |
|---|---|---|
| Auth / session | `authApi`, `refreshAccessToken`, `updateFCMToken`, `saveAppVersion`, `getAppVersionDetails`, `saveReferralLink`, `saveTokenUsage`, `logEventsApi` | **Keep**. Plumbing reused as-is. |
| Profile | `getProfile`, `saveProfile`, `updateAvatar`, `updateStandard`, `updateCredits`, `updateLifelines` | **Keep**, extend `getProfile` response with new career fields (XP, streak, badge counts), see §3. |
| Onboarding ref-data | `getClassOptions`, `fetchStates`, `fetchCities`, `fetchSchools`, `fetchLanguagesAndVoices` | **Keep** if onboarding still asks these. The career revamp may not need school/state/city for the homepage. |
| AI Tutor | `getAITutorPrompts(V2)`, `getAdditionalPrompts`, `generateTutorResponse`, `fetchChatResponse`, `createTutorAssistPrompt`, `fetchAiTeachers`, `transcribeAudio`, `retryTranscription` | **Keep if AI tutor stays inside missions**; otherwise deprecate later. Not on the new home. |
| Curriculum content | `fetchJourneys`, `fetchAllChaptersPerStandard`, `fetchChaptersV2`, `fetchChaptersToResume`, `fetchBooks`, `fetchChapterQuestionsApi`, `fetchConceptDetails`, `fetchCompletedConcepts`, `fetchLessonStory`, `fetchLessonQuestions`, `fetchLessonFlashcards`, `fetchRecommendedLessons`, `fetchTodayConcepts`, `resumeConcept`, `markLessonStart`, `markLessonCompletion`, `saveConceptConversations`, `checkConceptCheckpointCompleted`, `saveCheckpointResultApi`, `fetchCheckpointFeedback`, `fetchLessonHistory(List)`, `checkGreetingsAndIntroCompleted`, `resolveGap`, `updateLearningGapStatus`, `questionMistakesCorrection`, `fetchGeminiKeys` | **Mostly out of scope** for the career home, but stays alive as a separate "lessons" surface (if Tuto's school content lives on alongside careers). Otherwise **deprecate after migration**. |
| Quizzes | `fetchQuizzes`, `fetchQuizReport`, `markQuizCompleted`, `getDailyQuiz` | **Keep `getDailyQuiz` as the base for "Today's Job Challenge"**, see §4. Others stay for the existing quiz feature. |
| Gamification | `fetchAchievements`, `fetchPowerups`, `markPowerupUsed`, `giftPowerup`, `fetchRewardDetails`, `claimAndGetReward`, `fetchProgressReport` | **Keep**. Achievements feed the badge count; rewards feed activity completion popups. See §3 for XP/streak source. |
| Quests / Tasks | `fetchQuests`, `updateTaskStatus`, `startFriendQuest` | **Keep**. Repurpose: a "career mission" can be a task too, so `updateTaskStatus` may be the existing rail to record activity progress (see §4 — new APIs prefer a dedicated endpoint, but quests/tasks could be the backing model). |
| Leaderboard | `fetchLeaderboard`, `fetchLeaderboardResult`, `markLeaderboardResultSeen` | **Keep**. Not on new home, but in Play/Worlds/Passport tabs probably. |
| Social | `fetchFeeds`, `postFeed`, `reactOnFeed`, `fetchFriends`, `fetchFriendsProfile`, `fetchFriendSuggestions`, `addFriend`, `nudgeYourFriend` | **Keep**. Not on the new home but stays for social tab. |
| Feedback | `saveUserFeedback`, `submitFeedbackApi`, `fetchAllFeedbacks` | **Keep**. |

### 1.5 Existing tech debt worth fixing in this pass
- **No central base URL.** Every API file hardcodes `https://glutaclass.com:8080/…`. → introduce `lib/apis/_endpoints.dart` with a `const kBaseUrl` + path helpers; convert files as we touch them.
- **`getProfile.dart`** had `http://localhost:8080/…` commented out (caught), but
- **`fetchCheckpointFeedback.dart` ships `http://192.168.165.204:8080/…`** — a LAN dev IP. Will fail in production. **Fix.**
- Two profile-save endpoints (`/fam/profile` vs `/fam/add-profile`). Pick one (recommend `POST /fam/profile` with upsert semantics) and delete the other.
- `fetchJourneys` defaults `childUserId=child-1` — a hardcoded placeholder. Must come from `userTrackingId` or profile.
- 60+ files repeat the same `http.get/post + auth header + json.decode + try/catch` boilerplate. A thin **HttpClient wrapper** (one class) would shrink every file and centralize error handling, 401 → refresh-token, retries, timeouts.

---

## 2. Auth providers + phone-completeness gap

**Requirement:** support multiple sign-in providers (Google + Apple + Phone),
and for users who signed in **without** giving a phone (i.e. Google or Apple),
collect their number and verify it via OTP before letting them into the app.
Phone-auth users already have a verified number and skip the prompt entirely.

**The OTP plumbing already exists** (Firebase phone auth in `signupScreen.dart`
+ `otpPage.dart`). We just need to: (a) wire the right providers per platform,
(b) detect the missing-phone gap post-login, (c) route the user, and
(d) tell the backend the phone is OTP-verified.

### 2.0 Providers per platform

| Platform | Providers shown (in this order) | Required by store? |
|---|---|---|
| **Android** | Google, Phone | — |
| **iOS** | Apple, Google, Phone | **Apple is required** by App Store policy 4.8 whenever any third-party social login is offered. |

All three providers are **Firebase auth providers** under the hood, so the
backend receives the same shape — a Firebase ID token — regardless of which
button the user tapped. The backend distinguishes them by inspecting the
token's `firebase.sign_in_provider` claim (`google.com` / `apple.com` /
`phone`) for analytics and the post-login routing rule below.

Client additions needed:
- **Apple Sign-In dependency** (`sign_in_with_apple` Flutter package, already
  declared in `pubspec.lock`/`Podfile` for other reasons — confirm before
  building). Enable the **"Sign in with Apple" capability** in the iOS app
  identifier + Xcode entitlements; configure the Apple provider in Firebase
  Console.
- **Login screen platform branching** — render 3 buttons on iOS, 2 on Android.
  The handler for each provider ends in `FirebaseAuth.instance.signInWithCredential(...)` and the same
  `POST /howwow/auth/login` call (§2.5).

### 2.1 Flow change (client)
After `POST /howwow/auth/login` returns successfully (all three providers
converge here — §2.5 details the new login API). The response embeds the
profile, so we don't need a separate `getProfile` round trip:

```
loginResponse = POST /howwow/auth/login  { idToken }   // §2.5
   │   { appJwt, newUser, userTrackingId, profile }
   │   appJwt stored as "authKey"
   ▼
inspect loginResponse.profile
   │
   ├─ profile.phoneNumber present AND profile.phoneVerified == true     ┐
   │     → MainPage / Home                                              │ — Phone-auth users always
   │                                                                    │   land here on first login:
   │                                                                    │   the backend sees the phone
   │                                                                    │   claim in the Firebase token
   │                                                                    │   and marks phoneVerified=true.
   │                                                                    ┘
   │
   └─ otherwise   (Google + Apple sign-ins fall here on first login)
         → PhoneCollectionScreen (new)
              → reuse Firebase verifyPhoneNumber → OtpPage
                   → on verify success:
                        POST /howwow/auth/phone/verify (NEW endpoint, §2.3)
                        → MainPage / Home
```

**One branching rule covers everything:** the client never asks "which provider
was used" — it just inspects `phoneVerified`. Phone-auth users naturally pass.
Google/Apple users fail and route to the collection screen. The rule is
identity-provider-agnostic by design, so adding a fourth provider later
(WhatsApp, Microsoft, …) needs no client logic change.

### 2.2 Two client-side additions
- **`PhoneCollectionScreen`** — re-uses the existing `intl_phone_number_input`
  control from `signupScreen.dart`; pushes the same `OtpPage` on send.
- **Tweak `OtpPage._verifyOtp`**: on success, branch on "linking a phone to an
  already-authed user" vs "first signup". For the link case, call the new
  `POST /fam/phone/verify` instead of `sendIdTokenToBackend()` (the user is
  already authed by Google; we're just attaching a verified phone).

### 2.3 New backend endpoint
| Method | Path | Auth | Body | Response | Purpose |
|---|---|---|---|---|---|
| `POST` | `/howwow/auth/phone/verify` | Bearer appJWT | `{ "phoneNumber": "+91…", "firebaseIdToken": "<phone-credential-id-token>" }` | `200 { "phoneNumber": "+91…", "phoneVerified": true }` / `409` if number taken by another account | Backend re-validates the Firebase ID token (it carries the verified phone), stores `phoneNumber` + `phoneVerified=true` on the user, and (option) returns a refreshed appJWT. |

**Why a dedicated endpoint, not `POST /profile`:** the backend can prove the
phone was OTP-verified by inspecting the Firebase token's `phone_number` claim;
plain `POST /profile` lets the client write any phone string. This matters for
WhatsApp / re-engagement integrations later.

### 2.4 New profile fields the backend must persist
- `phoneNumber: string | null` — E.164 format.
- `phoneVerified: boolean` — true only after OTP success.
- (existing) all other profile fields untouched.

### 2.5 New login API — `POST /howwow/auth/login`
Replaces the implicit `GET /gluta/fam/auth?idToken=…` for the revamped flow.
Reasons to introduce a new one rather than reuse the legacy:
- A **POST with a JSON body** is the right shape for an auth request (the legacy
  smuggles an ID token through a query string, which is a security smell and
  shows up in nginx access logs).
- Returns a clearly versioned, typed payload (the legacy returns whatever the
  Java side happens to put in the map).
- Embeds the **profile in the response** so the home screen has everything it
  needs in one round trip after launch.

| Method | Path | Auth | Body | Response |
|---|---|---|---|---|
| `POST` | `/howwow/auth/login` | none (token is the credential) | `{ "idToken": "<firebase id token>", "platform": "android|ios|web", "appVersion": "1.2.17", "deviceId": "<id>" }` | `200 { "appJwt": "...", "newUser": bool, "userTrackingId": "...", "profile": { ...full profile from §3.1 } }` / `401` if Firebase verify fails |

Backend behaviour (Java/Spring sketch):
1. Verify the Firebase ID token via Firebase Admin SDK
   (`FirebaseAuth.getInstance().verifyIdToken(idToken)`) — **same Firebase
   project / service account already configured for the legacy `/gluta/fam/auth`**.
2. Read `firebase.sign_in_provider` from the token — one of `google.com`,
   `apple.com`, `phone`. Store it on the user record for analytics / future
   "you signed in last time with X" hints.
3. Look up the user by `firebaseUid` (or by `email`/`phoneNumber` for first
   sign-in via Google/Apple/Phone respectively).
4. Create the user if not found → set `newUser=true`. For the **phone provider**,
   also set `phoneNumber` + `phoneVerified=true` from the token's `phone_number`
   claim — this is what makes phone-auth users skip the collection screen in §2.1.
5. Issue the app JWT (`appJwt`) — same signer the legacy endpoint uses, so the
   existing `refreshAccessToken` flow still works.
6. Compose and return the profile per §3.1.

> **Apple "Hide My Email":** if the user chose Apple's relay address, the token's
> `email` will be an `@privaterelay.appleid.com` address. Treat it as the
> canonical email; do not try to resolve it. The Apple `name` is only provided
> on **first** sign-in — capture it from the client and store it on first call.

Other auth endpoints under the new namespace:

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/howwow/auth/refresh` | Refresh the app JWT before expiry (replaces `/gluta/famV2/refresh-token` for the new app). |
| `POST` | `/howwow/auth/logout` | Optional: invalidate refresh token on the server, clear FCM topic subscriptions. |
| `POST` | `/howwow/auth/phone/verify` | The phone-link endpoint from §2.3. |

---

## 3. Profile / Identity — modify what's there

### 3.1 Extend `GET /fam/profile` response (no breaking changes — additive)
```jsonc
{
  // existing fields (firstName, emailId, photoUrl, standard, schoolId, …)
  "userTrackingId": "u_abc123",
  "phoneNumber": "+919876543210",         // NEW
  "phoneVerified": true,                  // NEW
  "displayName": "Aarav",                 // NEW (greeting name, kid-friendly)
  "avatar": {                             // NEW (replaces avatarId for richer payload)
    "kind": "preset" | "image",
    "presetId": "boy_01" | null,
    "imageUrl": "https://…" | null
  },
  "stats": {                              // NEW — feeds the header pills
    "xp": 1250,
    "badges": 12,
    "streakDays": 7
  },
  "career": {                             // NEW — feeds the hero "Continue" card
    "currentMission": {
      "missionId": "m_2",
      "professionId": "satellite_engineer",
      "worldId": "space",
      "missionNumber": 2,
      "title": "How satellites talk to Earth",
      "skills": ["signals","antennas","mission_control"],
      "current": 2, "total": 5
    },
    "passport": {                         // NEW — feeds the Career Passport card
      "jobsExplored": 12,
      "badgesEarned": 12,
      "toolsCollected": 18
    }
  },
  "notifications": { "unreadCount": 3 }   // NEW — for the bell (if we add it back)
}
```
*Implementation note:* `stats.xp` and `streakDays` may already live elsewhere
(via `claimAndGetReward` and lesson completions). The right call is for the
backend to **aggregate** them into the profile response so the client makes one
call to draw the header, not three.

### 3.2 Modify
- `POST /fam/profile` — accept the new fields above (additive).
- `POST /fam/add-profile` — **deprecate**, merge into `POST /fam/profile`.

---

## 4. Career content — new APIs (the bulk of the work)

The homepage shows **four content surfaces**: Worlds, Professions, the user's
Current Mission (hero), and Today's Job Challenge. Long-tail: Career Passport,
Activity engine. Below is the full new surface.

> All endpoints: Bearer auth, `Accept-Encoding: gzip`, JSON, 200/4xx/5xx
> conventions, `Cache-Control: public, max-age=300` for the static content
> (worlds, professions, mission config) so the app can survive offline launches.

### 4.1 Catalog (mostly static content — cache aggressively)

| Method | Path | Purpose | Notes |
|---|---|---|---|
| `GET` | `/howwow/career/worlds` | List of worlds for the **Explore by World** row. | Returns `[ { worldId, name, accentColor, gradient, professionCount, sampleProfessions[], imageUrl, isLocked } ]`. Localize `name` via `Accept-Language`. |
| `GET` | `/howwow/career/professions` | Professions for **Try an Amazing Job**. Supports `?world=<worldId>&recommendedFor=<userTrackingId>`. | Returns `[ { professionId, name, worldId, description, iconKey, accentColor, gradient, imageUrl, missionCount, isRecommended } ]`. Server decides `isRecommended` (typically 1 per user — the active mission's profession). |
| `GET` | `/howwow/career/professions/{professionId}` | Detail page (for "View All Jobs" deep-dive screen later). | Includes the mission list for that profession. |
| `GET` | `/howwow/career/missions/{missionId}` | Mission config (storyboard, parts/elements, copy) for a specific mini-activity. | This is **the API the Build Satellite-style activities call** to get their parts/slots/steps. Can be a static blob for now; over time it becomes the runtime mission config. |

### 4.2 User-specific state (per-request, dynamic)

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/howwow/career/home` | **One aggregated call that draws the home screen.** Returns `{ profile.stats, currentMission, recommendedProfessions[5], worlds[4], todaysChallenge, passport }`. Saves 5–6 round trips at app launch. *(Recommended — see §6.)* |
| `GET` | `/howwow/career/current-mission` | Just the hero card data, if `/career/home` isn't built yet. |
| `POST` | `/howwow/career/missions/{missionId}/start` | Mark mission started (analytics + resume support). Returns the user's mission state (current step, installed parts, meters). |
| `POST` | `/howwow/career/missions/{missionId}/progress` | Save intermediate progress (e.g. parts installed so far). Body: `{ stepNumber, state: <opaque> }`. Used so the child can resume mid-mission. |
| `POST` | `/howwow/career/missions/{missionId}/complete` | Finalize. Body: `{ stepResults: [...], score, durationMs }`. Returns `{ xpAwarded, badgesAwarded[], newPassport, nextMission }`. **Drives the reward popup.** |
| `GET` | `/howwow/career/passport` | Full passport tab: jobs explored list with status (visited/completed), badges, tools. |
| `GET` | `/howwow/career/today` | Today's job challenge: `{ challengeId, profession, prompt, type, rewardXp, expiresAt }`. *(Alternative: extend `getDailyQuiz` with a `track=career` flag.)* |
| `POST` | `/howwow/career/today/complete` | Submit the daily challenge, get reward back. |

### 4.3 Activity engine (generalized, for the mini-activity-game skill)

The Build Satellite mission is currently hardcoded. As soon as the second
activity ships, the activity *config* should come from the server so we can
add/tune activities without releasing a new app build.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/howwow/career/activities` | List of activities the user can access (mapped to professions/worlds). |
| `GET` | `/howwow/career/activities/{activityId}/config` | The activity blueprint: catalog (parts/elements), slots/positions, steps/storyboard, mascot copy, asset manifest (paths under `assets/images/<id>/`). The **`mini-activity-game` skill's `config/` directory contents are exactly this**. |
| `POST` | `/howwow/career/activities/{activityId}/event` | Lightweight telemetry (drop-success, wrong-drop, hint-used). Optional but cheap to add. |

---

## 5. Map each homepage element → exact API call

| Screen element | API today? | API after revamp |
|---|---|---|
| Avatar + "Hi Aarav 👋" | partial (`getProfile`) | `GET /career/home` → `profile.displayName + profile.avatar` |
| Subtitle "What amazing job…" | static | static |
| XP / Badges / Streak pills | scattered (achievements, lesson rewards) | `GET /career/home` → `profile.stats` |
| Continue Career Mission (hero) | none | `GET /career/home` → `currentMission` |
| "Continue" CTA → opens mission | none | `POST /career/missions/{id}/start` on tap |
| Try an Amazing Job — 5 cards | none | `GET /career/home` → `recommendedProfessions[]` (or `GET /career/professions?recommendedFor=…`) |
| "View All Jobs" → deep list | none | `GET /career/professions` (paged) |
| Explore by World — 4 cards | none | `GET /career/home` → `worlds[]` (or `GET /career/worlds`) |
| Today's Job Challenge | partial (`getDailyQuiz`) | `GET /career/home` → `todaysChallenge` + `POST /career/today/complete` |
| Career Passport (3 stats) | partial (achievements + powerups) | `GET /career/home` → `passport`, deeper view via `GET /career/passport` |
| Bottom Nav — Home | n/a (this page) | n/a |
| Bottom Nav — Play | n/a | future: `GET /career/activities` |
| Bottom Nav — Worlds | n/a | `GET /career/worlds` |
| Bottom Nav — Passport | n/a | `GET /career/passport` |

---

## 6. Why `GET /career/home` (the aggregate) is worth it

Without it, a cold launch fires 5–6 sequential GETs to draw one screen.
A single aggregate:

- 1 RTT instead of 5–6 → noticeably faster first paint on flaky kid-tablet networks.
- Backend can co-locate joins (current mission ↔ profession ↔ world) and compute
  `isRecommended` consistently.
- Easy CDN/edge cache key per `userTrackingId` with short TTL (e.g. 60s).
- The individual endpoints in §4.1–4.2 still exist for the deep-dive screens
  ("View All Jobs", "View All Worlds", Passport tab) — `/career/home` just
  bundles the homepage.

---

## 7. Cross-cutting fixes to do during the migration

1. **Centralize the host:** `lib/apis/_endpoints.dart`
   ```dart
   class Endpoints {
     static const String baseUrl = String.fromEnvironment(
       'HOWWOW_BASE_URL',
       defaultValue: 'https://glutaclass.com:8080',
     );
     // New revamp surface — everything we build lives here.
     // Backend context-path is /gluta, so howwow paths nest under it.
     static String howwow(String p) => '$baseUrl/gluta/howwow$p';
     // Legacy surfaces — left for the existing curriculum app, do not extend.
     static String fam(String p) => '$baseUrl/gluta/fam$p';
     static String famV2(String p) => '$baseUrl/gluta/famV2$p';
     static String tutor(String p) => '$baseUrl/gluta/tutor$p';
   }
   ```
   Concretely: a call site reads `Endpoints.howwow('/career/home')` and gets
   `https://glutaclass.com:8080/howwow/career/home`.
2. **HTTP wrapper:** `ApiClient` with auth-header injection, 401→refresh-token retry, timeout, structured errors. Replaces the boilerplate in every existing file.
3. **Fix `fetchCheckpointFeedback`** to use the same base URL.
4. **Delete `/fam/add-profile`** after migrating to `POST /fam/profile` upsert.
5. **Make `fetchJourneys` use real `userTrackingId`** instead of `child-1`.
6. **Profile model in Dart:** typed `Profile`, `CareerHomeBundle` classes instead of `Map<String,dynamic>` everywhere — easier to evolve.

---

## 8. Build order (suggested)

1. **Cross-cutting:** `_endpoints.dart` + `ApiClient` (1–2 days; unblocks everything). Sets up the `Endpoints.howwow(...)` helper used everywhere below.
2. **New login** (§2.5): backend adds `AuthController.login` + `JwtAuthFilter`; client swaps `sendIdTokenToBackend()` for `POST /howwow/auth/login` and stores the embedded profile. (~2 days client + 1 day backend.)
3. **Phone-after-Google gap** (§2): new `PhoneCollectionScreen` + `POST /howwow/auth/phone/verify`; the login response from step 2 already carries `phoneNumber/phoneVerified` so the client just branches on them. (~2 days client, ~1 day backend.)
4. **Profile extension** (§3): backend adds `displayName`, `avatar.*`, `stats.*`, `career.*`, `notifications.*` to the profile payload (embedded in login + returned by `GET /howwow/profile`). Client typed model. (~2 days.)
5. **Career catalog APIs** (§4.1): `GET /howwow/career/worlds`, `GET /howwow/career/professions`. Wire the home cards. (~2 days client + backend.)
6. **`GET /howwow/career/home` aggregate** (§4.2 + §6): backend joins everything, single response. (~2 days backend.)
7. **Mission lifecycle** (§4.2): `start` / `progress` / `complete`. Wire to the Build Satellite mission so XP and reward popup come from the server. (~3 days.)
8. **Today's challenge** (§4.2): either repurpose `getDailyQuiz` or new `/howwow/career/today*`. (~2 days.)
9. **Activity-config endpoint** (§4.3): swap Build Satellite's local `part_catalog/slot_config` for a server-loaded blueprint (only do this once a second activity ships). (~3 days.)

---

## 10. Controller layout (backend)

Group the new endpoints into four Spring controllers. Each controller owns a
single root path under `/howwow/` and the related concerns. Cross-cutting
concerns (JWT verification, request logging, exception → JSON) live in a
filter / `@ControllerAdvice`, not duplicated per controller.

```
/howwow/auth                  AuthController
  POST  /login                 — verify Firebase id token, issue appJwt + embed profile  (§2.5)
  POST  /refresh               — refresh appJwt
  POST  /logout                — invalidate session + FCM topic
  POST  /phone/verify          — link an OTP-verified phone to the current user  (§2.3)

/howwow/profile               ProfileController
  GET   /                      — current user's profile (or use the one embedded in /auth/login)
  POST  /                      — upsert profile fields (replaces /fam/profile + /fam/add-profile)
  POST  /avatar                — change avatar (preset id or uploaded image)
  POST  /fcm-token             — register FCM token (replaces /famV2/update-fcm-token for the new app)

/howwow/career                CareerController
  GET   /home                  — aggregate payload for the homepage  (§4.2 — the big one)
  GET   /worlds                — list of worlds
  GET   /worlds/{worldId}      — world detail (deep view)
  GET   /professions           — list of professions, optional ?world=, ?recommendedFor=
  GET   /professions/{id}      — profession detail (mission list inside)
  GET   /current-mission       — hero card data (if /home not yet built)
  GET   /missions/{id}         — mission config (storyboard, parts, slots)
  POST  /missions/{id}/start
  POST  /missions/{id}/progress
  POST  /missions/{id}/complete
  GET   /passport              — full passport tab
  GET   /today                 — today's job challenge
  POST  /today/complete

/howwow/activities            ActivityController
  GET   /                      — activities this user can access
  GET   /{activityId}/config   — activity blueprint (parts/slots/steps; what the
                                 `mini-activity-game` skill's config/ directory
                                 mirrors today, served from the API tomorrow)
  POST  /{activityId}/event    — lightweight telemetry (drop, wrong-drop, hint)
```

Two cross-cutting pieces alongside the controllers:

- **`JwtAuthFilter`** — extract `Authorization: Bearer <appJwt>` for every
  `/howwow/**` request except `/howwow/auth/login` and `/howwow/auth/refresh`.
  Reject with `401` and a typed `{ error, code }` body on missing/expired.
- **`FirebaseTokenVerifier`** — single component used by both
  `AuthController.login` (verifies the sign-in id token) and
  `AuthController.phoneVerify` (verifies the phone-credential id token); reads
  the **same Firebase service account JSON** the legacy `/gluta/fam/auth` uses.

This split keeps every endpoint clearly homed and means a new mini-activity
ships by extending `CareerController` + `ActivityController` only — never
crossing into auth or profile.

## 9. Open questions for product / backend

1. Should school curriculum (chapters/concepts/AI tutor) coexist with careers in
   the same app, or does the career revamp eventually replace it? Determines
   whether the curriculum endpoints stay or get sunset.
2. Is "world" a strict container of professions, or can a profession belong to
   multiple worlds? (Spec says one-to-many; API assumes one-to-many.)
3. Daily challenge: same `getDailyQuiz` with a `track` flag, or a new endpoint?
4. ~~Should phone be required for all new sign-ups (including Google), or
   optional with the OTP prompt skippable?~~ **Answered:** required after Google
   and Apple sign-in; skipped for Phone sign-in (already verified). See §2.0–§2.1.
5. Avatar: upload custom photo, or preset library only? Determines whether we
   need an upload endpoint.
6. Push notifications for new missions / badges — already covered by `updateFCMToken`, but is there a backend topic-subscribe step we should be calling?
