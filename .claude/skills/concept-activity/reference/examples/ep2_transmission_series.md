# Worked example — EP2 electricity-transmission series

The "How Electricity Reaches Your Home" concept (Episode 2). Four sibling activities
that share ONE visual language — a transmission span (steel lattice towers + a
catenary wire) on a deep cool void — and the same controller-owns-everything
contract. Two are pure-Flutter, two are thin-Flame. Match this family when building
any further EP2 beat.

## The shared visual DNA (reuse verbatim)

- **One global key light: UPPER-LEFT** (`_lightUL = Offset(-0.7071,-0.7071)`).
- **Steel ramp** (towers / lattice / iron, ported between activities): edge `#1B2138`,
  body `#3C466B`, spine `#707FAE`, rim `#98A6D4`, bolt `#0C1430`, ceramic `#B9C4E6`.
- **Cool conductor body**: `#59648C` body / `#333C5E` edge / `#AEBCE6` specular.
- **Heat / ember** (the warm hero, reserved for heat/energy): core `#FF7A2E`, hot
  `#FFF1D8`, warm `#FFD27A`. **Transmission blue** (AC/DC pulses, NEVER warm):
  `#3FB9F5` / `#BFE6FF`. **Iron core** (2.6/2.7): `#161B36`/`#2C3768`/`#5F6FA8`,
  bevel `#8092C8`. **Copper coils**: `#C9844A`/`#F0BD82`, sheen `#FFE4BC`, back
  `#5A3A20`.
- **Dark-glass chrome** (every panel/dock/chip/scope): fill `#0B1026` @0.55–0.85,
  well `#05081A`, inner `0x14FFFFFF`, rim `0x26FFFFFF`, top catch-light white @0.05.
- **Glossy knob 4-stops**: warm `#FFE9B8→#FFD27A→#FF9A4E→#C7521A`; cool
  `#DCF1FF→#74C4F4→#2E78B6→#1B4A73`. **Switch-on green** `#5FE08A`.
- **Diagonal span**: left anchor LOW, right anchor HIGH; a catenary sag below the
  straight diagonal. The wire's drawn geometry is the HELD CONSTANT across beats —
  only its glow changes.

## Per-activity

### 2.3 Hot Wire — `current_heats_wire/` — **pure Flutter** (CustomPainter + Ticker)
- **Load-bearing rule:** current forced through resistance gives off heat = the
  transmission LOSS (energy leaves the wire as heat *instead of reaching the city*).
  Hard-gated: motes/current/lamp hard-zero the same frame the slider hits the cutoff.
- **Scene:** PLANT→CITY span (no bulb — the receiving tower IS the destination).
  Loss-gradient ember (hottest at PLANT, cooling toward CITY via
  `ui.Gradient.linear(wirePoint(0), wirePoint(1), …)`), white-hot blow-out +
  anamorphic streak + breathing. Steel towers, warm glossy slider, grounded
  PLANT/CITY base-plates, SAME WIRE annotation pill.
- **Captions:** 6 lines (Raise → felt → Drop / Rub → felt / Raise again → loss).

### 2.4 Squared Loss — `squared_loss/` — **pure Flutter** (CustomPainter + Ticker)
- **Load-bearing rule:** loss grows with the SQUARE of current (×2 → 4×, ×3 → 9×).
  The glow VOLUME leaps with I², not the number.
- **Detented ×1–×4 slider** — the classic bug: tick labels at full-span `(d-1)/3`
  but the handle/value normalized to the active range → ×2 read 1.4. Fix: both use
  the full span; the active range only CLAMPs.
- **Graph = a CENTRED modal** with labelled axes (X: ×1–×4 current; Y: 1×/4×/9×/16×
  heat gridlines), the learner's glowing curve, a dashed ghost (linear) line, and
  ×2/×3/×4 point markers with dotted drop-lines to both axes. DISMISSES completely
  (slide + fade) when done — never dims.
- **Captions:** 9 lines (the LOST VOLTS → I²R algebra derivation was CUT as over-reach;
  ends on one naming line + the card).

### 2.6 The Transformer — `the_transformer/` — **thin Flame**
- **Rule:** a transformer steps voltage by the coil-turns ratio; the steel-tower span
  carries it. (Sibling — shares the iron-core + copper-coil + steel craft used in 2.7.)

### 2.7 AC and DC — `ac_vs_dc/` — **thin Flame** (11-layer Component tree)
- **Load-bearing rule:** a transformer works only on a CHANGING current — AC supplies
  the change forever, DC doesn't. The honest sim, hard-gated every frame:
  `current → field (lagged, τ≈0.08) → fieldRate=|Δfield/dt| → output = (fieldRate>eps
  ? f(rate) : 0) → bulb (fast attack, INSTANT release — snaps dark)`. DC and AC reach
  the SAME amplitude (1.0) so DC fails as CHANGELESSNESS, not weakness ("change, not
  magnitude").
- **Renderer:** `AcdcGame` (FlameGame, transparent bg) adds 11 layers
  (ambient → bg-glow → input-line → output-line → core+flux → primary/secondary coils
  → dock → bulb → graph → flash). `onGameResize→setStageSize`, `update→tick`. INPUT is
  a transparent Flutter `Listener` → `controller.onTapDown` (hit-tests
  `switchHit`/`batteryHit`).
- **Controls:** a battery in its OWN dark-glass compartment + a separate **smooth
  horizontal toggle** power switch (landscape `0.20w × 0.055h`; pill track + green
  flood + glossy knob, driven by `connectRamp`). Switch starts the circuit; tapping
  the battery flips its polarity.
- **Wires:** clean hand_crank_lamp style (`_leadWire`: bowed quad-bezier glow +
  path-metric pulses, NO lugs); output joins the bulb at `bulbBaseDrop(c.bulbRadius)`,
  bowed UP over the core. Input anchors to the primary coil-bottom (`limbX`,
  `center + 0.4·coreOuterH`).
- **Bottom scope:** a CURRENT strip-chart; the trace plots in its own area BELOW the
  CURRENT label so a DC `+1` line doesn't ride into the label.
- **Captions:** 9 lines (intro silent; one dead line; flip/blink; law; reverses;
  alive; one naming line "Steady is DC. Reversing is AC."; the rule). Name-last —
  DC/AC/hertz absent until the alive/naming phases.

## On-device tuning notes (all single-const)

- Geometry collisions are the #1 on-device fix: lower a hero off the top-text seat,
  add a gap above a bottom scope, re-anchor a wire to its component. See the
  Geometry & placement rules in SKILL.md.
- Everything is a factor in `*_tuning.dart` (palette + geometry + the ms phase
  schedule). The user iterates live with hot-reload; values are first-pass.
- `fvm dart analyze lib/screens/missions/<id>` after every change (never repo-wide).
