# Episode-board evidence frames ("perfect" pre-kept moments)

Drop one PNG per evidence tile here, named by the tile **id**. These are the
hand-picked, perfectly-framed stills of each felt moment — shown as the captured
evidence on the board and in the "Make Your Case" closing flow. The activity plays
the capture animation over them; it no longer grabs a live screenshot.

If a file is missing, that tile falls back to its drawn motif (the build still
works) — so you can add them incrementally.

Tiles are rendered square with `BoxFit.cover`, so a **square (or near-square) crop
framed tightly on the moment** looks best (~512×512 is plenty).

## Episode 1 — files expected (8 tiles)

| filename | the moment |
|---|---|
| `same_magnet.png` | the convergence — every source spins the SAME coil/magnet |
| `fossil_haze.png` | the skyline choking in smog (coal **and** gas — clubbed) |
| `nuclear_cost.png` | the cost meter soaring (nuclear is clean but expensive) |
| `wind_drop.png` | the town gone dark when the wind drops |
| `solar_night.png` | the town dark at night (solar asleep) |
| `hydro_river.png` | the dammed river (clean + steady, but only where rivers run) |
| `still_magnet.png` | a still magnet → dark bulb (it only works while moving) |
| `turbine_spin.png` | a turbine spinning the magnet |

> Note: a newly-added asset needs a full app re-run (`flutter run`), not just hot
> reload, before it shows up.
