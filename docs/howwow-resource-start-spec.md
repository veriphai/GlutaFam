# Resource-start tracking — backend spec

**Status:** client side already shipped (fire-and-forget, 404-tolerant). The app
works fine without this; deploying it lights up the features below with **no
app release needed**.

## Why

Today the server only learns about a lesson when a resource **completes**
(`POST /resources/{idx}/complete`). That leaves three gaps:

1. **"Opened but nothing finished" is invisible.** A kid taps Episode 3,
   watches half the intro video, backs out → server has zero record. The home
   card says "Start" instead of "Continue", and re-engagement nudges can't
   fire.
2. **No freshness.** We can't tell "left Episode 3 five minutes ago" from
   "five days ago".
3. **The home card can't show step progress** — `currentLesson` doesn't carry
   `lastCompletedResourceIndex`, so "Resume — step 2 of 3" is impossible
   without a detail round trip.

Note: the *current resource index* itself stays **derived** —
`lastCompletedResourceIndex + 1` (completion is monotonic, so this never
disagrees with a stored pointer). This spec adds the start/freshness signal,
not a second progress pointer.

## 1. New endpoint

```
POST /gluta/howwow/lessons/{lessonId}/resources/{resourceIndex}/start
Authorization: Bearer <appJwt>
Body: {"type": "video" | "image" | "activity"}
```

The app fires this **before pushing each resource screen** (same loop spot as
the analytics `resource_started` event). Fire-and-forget; the app never blocks
on it.

**Server behaviour** — on the per-(user, lesson) progress doc
(`howwow_lesson_progress`):

| Field | Behaviour |
|---|---|
| `startedAt` (ts) | set **once**, on the first `/start` ever for this (user, lesson) |
| `lastResourceStartedIndex` (int) | overwrite on **every** call |
| `lastResourceStartedAt` (ts) | overwrite on **every** call |
| `lastResourceStartedType` (string) | overwrite on **every** call (optional but cheap; useful for nudge copy) |

Rules:
- **No monotonic enforcement** (unlike `/complete`). This is informational
  state, not an unlock gate — accept any index in `[0, resources.length)`.
- **Idempotent** — repeated identical calls are harmless overwrites.
- Validate the lesson exists and belongs to an unlocked chain position;
  otherwise 404/403 as `/complete` does today.
- Response body: `200 {}` is fine — the client ignores it.
- **404 contract:** until this route is deployed the client receives 404 once,
  latches off, and stops calling for the session. So partial rollout is safe.

## 2. DTO additions (read path)

### `/career/home` → `currentLesson`

```jsonc
{
  "lessonId": "satellite_engineer_m3",
  // ... existing fields ...
  "lastCompletedResourceIndex": 0,   // NEW — same semantics as detail DTO; -1 = none
  "startedAt": "2026-06-07T09:12:33Z" // NEW — null = never opened
}
```

Client renders (already implemented, lights up automatically):
- badge/CTA: **"CONTINUE"** when `startedAt != null || lastCompletedResourceIndex >= 0`
  (today it only flips after a full lesson completes)
- hint line: **"Resume step 2 of 3 — the mission!"** (step = lastCompleted+2,
  type from `resources[]`)

### `/career/professions/{id}/detail` → `lessons[]`

```jsonc
{
  "lessonId": "satellite_engineer_m3",
  // ... existing fields ...
  "started": true   // NEW — startedAt != null on the progress doc
}
```

Client renders (already implemented): timeline `isPartiallyStarted` (resume
copy) now also covers "opened the intro, backed out" instead of only
"completed ≥1 resource".

## 3. What this unlocks later (not in this spec)

- Re-engagement push: "You left Episode 3 mid-way!" — query progress docs
  where `startedAt` set, lesson incomplete, `lastResourceStartedAt` older than
  N hours. All fields needed are written by this spec.
- Server-side drop-off funnels per resource index (start vs complete deltas)
  without relying on the lossy analytics event queue.

## 4. Client reference (already merged)

- API fn: `howwowMarkResourceStarted` — `lib/apis/howwow/howwowProgress.dart`
- Runner wiring + 404 latch: `_postStart` — `lib/screens/missions/lessonRunner.dart`
- DTO parsing: `HowwowCurrentLesson.{lastCompletedResourceIndex,startedAt,started,nextResourceIndex}`
  (`howwowProfile.dart`), `HowwowDetailLesson.{startedOnServer,started}` (`howwowCareer.dart`)
- UI: `ContinueMission.{inProgress,resumeStep,...}` + card copy
  (`careerModels.dart`, `careerMissionCard.dart`), timeline `Lesson.isPartiallyStarted`
  (`professionDetailModels.dart`)
