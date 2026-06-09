# Power Balance Challenge (Episode 6 — "Keep the Satellite Alive")

**Mechanic:** real-time **resource-management sim** — keep a satellite's battery
> 0 while orbiting through sunlight → cyclone target → ground-station range →
Earth's shadow, charging via solar panels and spending power on camera/antenna/
thruster. Win = 3 cyclone images captured **and** 3 data packets sent with battery
left; lose = battery hits 0.

**Tech chosen + why:** **Flutter shell + one Flame stage built once**, the
**controller-owns-geometry** pattern (the `signal_rescue` sibling). The core logic
is *continuous* (battery × zone × solar × tool-drain computed every frame), so the
controller owns the simulation **and** the scene geometry (factor-anchors × the
stage size the game reports once); the Flame game is a **pure renderer + clock**
that owns **zero gestures** — every control is a Flutter dock button calling a
controller intent (the inverse of in-stage aiming, like Orbit Launcher).

## Module layout
```
lib/screens/missions/power_balance/
  power_balance_screen.dart            # shell: Positioned.fill stack, built-once GameWidget
  config/asset_paths.dart              # PB registry (.flame/.flutter) + preload list
  config/power_balance_tuning.dart     # ALL PRD constants + zone bounds + factor anchors + copy
  models/power_balance_models.dart     # OrbitZone, MissionPhase, SolarAlignState, MascotMood, ControlHint
  state/power_balance_state.dart       # immutable copyWith state + transient FX tokens
  state/power_balance_controller.dart  # the brain: orbit clock+holds, battery sim, phase machine
  state/analytics.dart                 # no-op
  game/power_balance_game.dart         # renders from controller; fires FX by token-diff
  game/components/scene_components.dart # EarthCurve (day↔night), SatelliteSprite (state swap+blink), ShadowScrim
  widgets/pb_palette.dart              # styleboard colours + safe pbImage() helper
  widgets/top_mission_hud.dart         # title + battery pill + Images/Data counters + zone badge
  widgets/control_dock.dart            # 4 active/inactive icon buttons, highlight+enable gating
  widgets/mission_control_card.dart    # avatar (mood) + label + message
  widgets/mission_overlays.dart        # intro start page + success + failure
```

## Reused vs new
- **Reused (plumbing):** signal_rescue's whole shape — `ChangeNotifier` controller
  owning immutable `copyWith` state; built-once `GameWidget` in `initState`;
  `Positioned.fill` cosmic-bg → game → SafeArea overlay; `_spawnEffect` additive FX
  helper; flame/flutter asset-registry split; reused app SFX; `careerTheme`/
  `careerCommon` kit; activities-hub one-line entry.
- **New (behaviour, authored from THIS PRD):**
  - **Guided-orbit HOLD:** the orbit advances toward a hold point per tutorial
    phase (`holdSunlight/holdTarget/holdGround`) then **freezes there until the
    child acts**, then flows freely in `freeMissionLoop`. Makes the first
    capture/send reliable without hard-gating; free play times the zones.
  - **Verbatim battery sim** (PRD §11.1): `delta = -base (+solar if sunlit&aligned)
    (-camera)(-antenna)`, thruster instant −8; `isCharging = delta>0.3`.
  - **Presence/fade getters** (`shadowFactor`, `sunPresence`, `cyclonePresence`,
    `groundPresence`) computed in the controller from orbit progress (smoothstep
    ramps) so the game is a pure renderer — the WORLD fades in/out per zone.
  - **Full-traverse elliptical orbit** (decided WITH the user — the PRD §18
    "looping movement along orbit path" vs the mock's centred-satellite framing is
    a genuine fork; ASK). `orbitPointPx(p) = orbitCenter + (rx·sin 2πp, −ry·cos
    2πp)` — always-visible ellipse (full width, bottom stays above the Earth limb +
    dock), loops cleanly (closed curve, no wrap teleport). Key unlock that kept it
    coherent: the **capture beam + data packets connect satellite→cyclone/dish
    DYNAMICALLY**, so the satellite only needs the right *zone* (progress), never
    exact spatial alignment — cyclone/dish stay fixed Earth anchors and the beam
    bridges the gap. Orbit path drawn as a **programmatic ellipse ring**
    (`OrbitEllipse`, additive `drawOval` glow+core) that matches the satellite's
    path exactly (a fixed dome sprite wouldn't). Guided HOLDs must be in increasing
    progress order (`holdSunlight 0.12 < holdTarget 0.33 < holdGround 0.48`) — the
    `p<hold` ease-to logic can't wrap.
  - **Token-diff FX:** state carries bump-counters (`captureToken/sendToken/
    chargeBurstToken/thrusterToken/warnToken`); the game caches last values and
    fires a one-shot effect when one changes — clean fire-on-event with no
    game-side logic.
  - **Message-hold latch:** event copy (capture/send/wrong-use/thruster) sets
    `_msgHold`; the per-frame ambient zone-nudge copy only runs once it expires, so
    "Image captured!"/warnings aren't stomped by the next tick's zone message.

## Gotchas hit
- **Baked-checkerboard-in-RGB on soft-gradient overlays.** `earth_shadow_overlay`,
  `shadow_dark_vignette`, `power_down_overlay` PASSED the corner-alpha probe (dark
  corners α=0) but their soft-gradient interiors were **opaque checker** in RGB.
  Dropped all three → did shadow via an `earth_curve_day↔night` crossfade + a
  programmatic `ShadowScrim` gradient, and failure via a Flutter dark scrim. Cleaner
  AND avoids the checker. (Reinforces the existing "transparent corners ≠ clean
  interior" gotcha — soft gradients are the prime suspect.)
- **Ring/frame HUD centres = baked checker.** `charging_status_glow`,
  `camera_target_lock_overlay`, `power_down_overlay` had clean bright frames but
  checker-filled enclosed centres; re-stripped with `--min-hole-area 3000` to punch
  the centre (target-lock + charging-glow came out clean; power-down stayed ragged →
  dropped). Additive glows tolerate a faint centre; HUD frames over content don't.
- **`images.fromCache` throws if not preloaded.** The token-diff FX spawn sprites
  on demand (`lowPowerGlow`, `dataSuccessBurst`) that weren't in `preload` → would
  crash the first time a wrong-use/send fired (analyze + APK build don't catch it;
  only the runtime path does). **Every sprite any spawn path touches must be in the
  preload list**, not just the ones added in `onLoad`.

## Asset prep
110 MB raw → **23 MB**, 75 assets: 72 transparent PNGs (light-checkerboard border
flood-fill + trim + downscale 512) + 3 full-bleed JPEG backgrounds (space/day/night).
3 baked-checker overlays dropped for programmatic equivalents.

## Post-build audit (re-read PRD vs code)
Caught + fixed: 7 PRD feedback assets were unused → wired a **badge-pop overlay**
(`image_captured`/`data_sent`/`shadow_warning`/`sunlight_mode`/`power_warning`
badges + live cyclone thumbnail), a **charging-glow halo** on the satellite, and
the **retry badge** in failure; prompt timing gated to the actual zone; battery
number tween fixed. Final coverage 66/75 — the 9 left are redundant AI *alternates*
of assets already shown (documented). The asset-usage grep (`PB.<const>` used vs
defined) is the fast way to audit criterion §22.13.

## Status
Compiles clean (`fvm dart analyze` → no issues), full APK builds, boots on Chrome
with no exceptions. **Scene factor-anchors + battery balance pending the on-device
visual-QA loop** (orbit ellipse radii/center, cyclone/dish/sun placement,
additive-glow levels over the bright sun, charge/drain feel, tutorial pacing).

## Voice-over integration (54-line Orbit track + BGM)
- Source files `scene-N-orbit-determining.wav` (1..54) + `bgm.mp3` → copied as
  `assets/sounds/power_balance/orbit/orbit_NN.wav` + `bgm.mp3`; mapping verified
  by the size sanity-check (shortest line = smallest file). Both folders declared
  in pubspec (not recursive).
- **Choke-point voicing** (see SKILL.md): `PBTune.orbitClipFor` (line const →
  clip no) + the controller's `_mut` stamps `voiceClip`/`voiceToken` whenever
  `helperMessage` changes. Multi-line beats (crisis 4-liner, solar 3-line teach,
  camera/antenna warn chains, pre-shadow "charge now") are `_followUps` queue
  entries — drained one per `messageHold` expiry, and the hold FREEZES while
  `_voiceActive`, so the whole script is voice-paced with a timer fallback when
  muted.
- Screen: 3 audio lanes (`_sfx`/`_voice`/`_bgm`), per-player
  `AndroidAudioFocus.none` + iOS mixWithOthers, BGM ducking 0.20→0.05 under
  Orbit. Intro lines 1..3 chained screen-side via a `ValueNotifier<int>` bubble
  index; success 50→51→52 and failure 53→54 chained in the completion router.
- Dialogue triggers added in the same pass: pre-shadow HOLD beat (orbit parks at
  0.525 for "Shadow ahead / Charge now"), shadow good-save praise, free-play
  "think like an engineer" one-shot, capture/send praise, thruster
  first/spam/good-choice tiers, mid-game POWER-CRITICAL recovery pair
  (M1 "still alive" → M2 "wrong time"), "that was close" on a scraped shadow
  exit (tutorial + free-loop zone-transition check).
