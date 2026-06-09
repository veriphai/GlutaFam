# Howwow FCM notifications + deeplinks

Reference for the Python notification service. Documents the URL catalog
the Flutter app accepts and the FCM payload shape that routes a tap to the
right in-app screen.

## URL scheme

The Flutter app registers the **`howwow://`** custom scheme on both
Android (`AndroidManifest.xml`) and iOS (`Info.plist`). Notifications
include a URL string under `data.url` and the device routes the tap to
`HowwowDeeplinkRouter.handle(uri)`.

### URL catalog

| URL | Lands on |
|---|---|
| `howwow://home` | Career home screen (the default landing if no specific target) |
| `howwow://world/{worldId}` | World detail (falls back to home until the world screen ships) |
| `howwow://career/{professionId}` | Profession detail screen |
| `howwow://career/{professionId}/lesson/{lessonId}` | Profession detail, with the lesson row visually highlighted |
| `howwow://career/{professionId}/lesson/{lessonId}?action=start` | Profession detail; auto-opens the lesson runner **iff the lesson is unlocked** for that user |

### Optional query params

Append to any URL with `?` (use `&` to add more):

| Param | Purpose |
|---|---|
| `deeplink_id` | Backend-generated UUID per send. Threaded through to the `notification_tapped` analytics event so a campaign's `lesson_started` / `lesson_completed` events can be attributed back to it. |
| `source` | Where the URL came from. Defaults to `"push"` for FCM origin. Useful when reusing the same URL across email/web. |
| `action=start` | Lesson URLs only — request auto-start of the lesson runner. Locked lessons silently ignore this and land on the profession page (per design option A). |

## FCM payload shape

The Python service should send a **mixed `notification` + `data`** message
to Firebase. `notification.title` / `notification.body` drive what the
system shows in the tray; `data.url` is what the device routes when the
user taps.

```json
{
  "to": "<fcmToken>",
  "notification": {
    "title": "New lesson unlocked!",
    "body": "Choose the Right Satellite is ready in Satellite Engineer."
  },
  "data": {
    "url": "howwow://career/satellite_engineer/lesson/satellite_engineer_m5?deeplink_id=abc-123&source=push",
    "deeplink_id": "abc-123"
  },
  "android": {
    "priority": "high"
  },
  "apns": {
    "headers": { "apns-priority": "10" },
    "payload": {
      "aps": { "sound": "default" }
    }
  }
}
```

### Why mix `notification` + `data`

`notification`-only messages let FCM auto-show the system notification but
don't always invoke our `onMessageOpenedApp` handler on iOS background.
`data`-only messages don't show a system notification at all. The mixed
form gets both: system-rendered tray entry + reliable `data.url` delivery
to the Flutter `onMessageOpenedApp` listener.

### `data` field constraints

- All values must be **strings**. Numbers, booleans, nested JSON must be
  serialised at the Python layer.
- Total payload size limit: 4 KB.
- The Flutter side reads only `data.url` today; everything else in `data`
  is forwarded as event props on `notification_tapped` for analytics
  (when we add that read path).

## Example payloads

### "Continue your lesson" — auto-open the runner

```json
{
  "to": "<fcmToken>",
  "notification": {
    "title": "Pick up where you left off",
    "body": "You're halfway through Build the Satellite!"
  },
  "data": {
    "url": "howwow://career/satellite_engineer/lesson/satellite_engineer_m4?action=start&deeplink_id=resume-2026-06-04",
    "deeplink_id": "resume-2026-06-04"
  }
}
```

### "New career to explore" — land on profession page

```json
{
  "to": "<fcmToken>",
  "notification": {
    "title": "Meet the AI Engineers",
    "body": "Teach machines to think — explore the AI Engineer path."
  },
  "data": {
    "url": "howwow://career/ai_engineer?deeplink_id=launch-ai",
    "deeplink_id": "launch-ai"
  }
}
```

### "Explore a new world" — land on world page

```json
{
  "to": "<fcmToken>",
  "notification": {
    "title": "Welcome to Ocean World",
    "body": "Marine biology adventures await."
  },
  "data": {
    "url": "howwow://world/ocean?deeplink_id=ocean-launch",
    "deeplink_id": "ocean-launch"
  }
}
```

### "Generic re-engagement" — just open the app to home

```json
{
  "to": "<fcmToken>",
  "notification": {
    "title": "We miss you, Cosmic Explorer!",
    "body": "Open howwow and see what's new."
  },
  "data": {
    "url": "howwow://home",
    "deeplink_id": "reengagement-2026-06"
  }
}
```

## Behavioural notes

1. **Auth gating.** If the user is signed out when they tap a URL that
   requires auth (`career`, `lesson`, `home`), the app stashes the URL,
   routes through login (+ phone collection + onboarding if applicable),
   then consumes the stashed URL after auth completes. The user lands on
   the deeplink target, not the default home screen.
2. **Locked-lesson policy.** A `?action=start` URL for a lesson the user
   hasn't unlocked yet lands them on the profession detail page with that
   lesson visibly locked. The auto-start hook silently no-ops.
3. **Cold start vs background.** Both work. FCM cold-start tap routes via
   `FirebaseMessaging.instance.getInitialMessage()` once the app is up;
   background tap routes via `onMessageOpenedApp`. Foreground messages
   trigger a local notification render but DO NOT auto-navigate (the user
   chose to be inside the app — yanking them elsewhere is rude).
4. **Idempotent / safe.** Unknown URLs (typos, future paths) are silently
   ignored with a debug log. They never crash the app.
5. **Analytics emission.** Every successful URL parse fires the
   `notification_tapped` event with `{url, deeplink_id, source,
   target_type}` so we can build the funnel "push sent → notification
   tapped → lesson started → lesson completed" keyed by `deeplink_id`.
