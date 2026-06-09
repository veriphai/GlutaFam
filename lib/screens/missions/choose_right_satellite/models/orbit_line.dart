// One Orbit (mascot) dialogue line paired with its master-script voice clip
// number. Clips are numbered in script order; when VO lands, clip N plays from
// assets/sounds/choose_right_satellite/orbit/orbit_NN.mp3 (audioplayers
// AssetSource path: 'sounds/choose_right_satellite/orbit/orbit_NN.mp3').
// A null clip = text-only line (no recording).

class OrbitLine {
  const OrbitLine(this.text, [this.clip]);

  final String text;
  final int? clip;
}
