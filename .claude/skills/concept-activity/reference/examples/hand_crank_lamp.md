# Worked example — Handle Lamp (beat P.1)

The first `concept-activity`. PRD: `prd_prologue_hand_crank_lamp_v2.md`. Lives at
`lib/screens/missions/hand_crank_lamp/`. Wired as the Prologue resource of the
"How Electricity Reaches Your Home" WOW concept (`wowConcepts.dart`).

This example teaches **methodology + code contracts**, not a look to copy. Build
each new activity's behaviour from ITS PRD.

## The load-bearing rule
**Electricity isn't stored — stop making it and the light dies instantly.** The
kid cranks a handle → a bulb lights; the moment they stop, it's dark, no fade.
Then the same handle drives a fan, heater, speaker (same energy → different
output). Synthesis: "One Handle — Light, Motion, Heat, Sound."

## File map
```
hand_crank_lamp_screen.dart     # shell: Ticker clock, vertical layout, BGM, earn overlay
config/
  crank_config.dart             # factor-based geometry + physics tuning (the tuning surface)
  output_defs.dart              # the 4 outputs (lamp/fan/heater/speaker) + bloom colours
  sequence.dart                 # kSequence StepDefs (device + caption + diesText) + kDoneText
state/
  crank_controller.dart         # ChangeNotifier: physics + geometry + sequential step machine
  crank_particles.dart          # ParticleField: spawnSparks/Embers/Wind/Motes, update, clear
widgets/
  crank_surface.dart            # pointer → controller; hosts CustomPaint(StagePainter)
  stage_painter.dart            # the single painter: surface, bloom, rays, wire, box, output, shaft, crank, particles
  instruction_banner.dart       # caption (sequential fade) + progress dots
  bulb.dart                     # paintBulb() — shared glass bulb (ported from trace_it_back)
```

## Layout (vertical, sibling-matched)
Device (top) → wire → **generator box** → shaft → **handle** (bottom). Echoes
Trace It Back's turbine→magnet stack. All anchors `dx = 0.5` (centred); verified
via PIL centroid (bulb/box/hub all within ~1px of centre). Tuning lives in
`crank_config.dart`: `outputFactor (0.5,0.185)` r `0.21`, `boxFactor (0.5,0.53)`,
`pivotFactor (0.5,0.84)`, `handleLenFactor 0.225`. "Make it bigger / longer wire /
move it" were all one-line factor edits.

## Key contracts (copy these patterns, not the values)

**Instant cutoff (the rule), in `tick()`:**
```dart
if (_isGenerating) {
  final target = CrankConfig.brightnessCurve(_energyInput);
  _brightness += (target - _brightness) * (1 - math.exp(-dt / CrankConfig.rippleTau));
} else {
  _brightness = CrankConfig.stopBrightness; // == 0, same frame
}
// pulse, spinAngle, particles all gated on _isGenerating; particles.clear() on stop.
```

**Step machine advance:**
```dart
if (!_stepLit && _brightness >= clearlyLitThreshold) _stepLit = true;
if (wasGenerating && !_isGenerating && _stepLit && !_diedHolding) {
  _startDiscoveryFlash();
  final dies = kSequence[stepIndex.value].diesText;
  if (dies != null) { _diedHolding = true; _diedElapsed = 0; _updateInstruction(); }
  else _advanceStep();
}
if (_diedHolding) { _diedElapsed += dt;
  if (_diedElapsed >= 1.8 && !_isGenerating) { _diedHolding = false; _advanceStep(); } }
```

**Caption banner — sequential (no overlap):** `instruction_banner.dart` holds one
`AnimationController`; on a new caption it `reverse()`s (fade out), and a status
listener swaps the string at `AnimationStatus.dismissed` then `forward()`s (fade
in). A caption arriving mid-fade is queued in `_pending` and applied at the next
dismissed. Font auto-shrinks for the long synthesis line.

**Coin-toss card reveal:** `CollectibleCardView(tossOnEnter: true)`. Combined angle
`= (1 - Curves.decelerate(_toss.value)) * 3 * 2π + _flip.value * π`;
`showBack = (angle % 2π) ∈ (π/2, 3π/2)`. Earn overlay passes `tossOnEnter: true`;
reduced-motion sets `_toss.value = 1`.

**Image card faces:** `kConservationCard` sets `frontImage`/`backImage`
(`assets/images/collectibles/conservation_{front,back}.png`, 1254² squares). The
card view + earn overlay switch to **square** sizing when `hasImageFaces`; the PNG
is the whole card (no procedural frame); the back renders normally (parent flip
mirrors it).

**Audio-focus fix (BGM bed):**
```dart
await _bgm.setAudioContext(AudioContext(
  android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
  iOS: AudioContextIOS(category: AVAudioSessionCategory.playback,
    options: const {AVAudioSessionOptions.mixWithOthers}),
)).catchError((_){});
_bgm..setReleaseMode(ReleaseMode.loop)..play(AssetSource('sounds/hand_crank_lamp/bgm.mp3'), volume: 0.18);
```

## Premium pass specifics
Energy-field background (`activity_background.dart`/`ActivityDossierBackground`),
light rays from the lit device, `ParticleField` sparks at the knob + per-output
debris, crafted crank (flange + bolt-heads + recessed housing + grip-ridged knob),
cylindrical shaft with travelling rib-rings, sealed "black-box" generator (dark
port that glows when working — **no spinning rotor inside**: a rotor read as a
second fan). Off-state steel lifted to bright blue (`~0xFF54649E` bodies,
`0xFFAEB9E8` edges) so it survives the dark background.

## Verify recipe (headless)
```python
# /tmp/shot.py — drive the crank + screenshot WHILE cranking (instant cutoff!)
import time; from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(); pg=b.new_page(viewport={'width':412,'height':915}, device_scale_factor=2)
    pg.goto('http://localhost:8767'); time.sleep(16)
    pg.evaluate("""()=>{const cx=206,cy=690,r=46;const t=document.elementFromPoint(cx+r,cy)||document.body;
      const ev=(ty,x,y)=>t.dispatchEvent(new PointerEvent(ty,{pointerId:1,pointerType:'touch',isPrimary:true,clientX:x,clientY:y,buttons:1,bubbles:true,cancelable:true}));
      ev('pointerdown',cx+r,cy);let a=0;window.__c=setInterval(()=>{a+=0.7;ev('pointermove',cx+r*Math.cos(a),cy+r*Math.sin(a));},16);}""")
    time.sleep(2.2); pg.screenshot(path='/tmp/lit.png'); b.close()
```
Serve with `fvm flutter run -d web-server --web-port 8767 -t lib/_preview.dart`
(a throwaway `_preview.dart` booting `HandCrankLampScreen`; restore it after).
Const config edits need a **restart** (no web hot reload). Centre-alignment was
confirmed with a PIL centroid scan, not the eye.

## On-device tuning notes (history)
Built mascot-first (Voltix + VO + dialogue engine), then **deleted all of it** for
captions — the decisive quality jump. Sequenced from horizontal (handle→box→bulb)
to **vertical** to match the sibling. Box rotor removed (looked like a 2nd fan).
Contrast lifted twice. Hero + handle scaled up to fill space. Wire lengthened ~35%.
Card swapped from procedural to supplied image faces + coin-toss. Each was a small,
verified change from a one-line note.
