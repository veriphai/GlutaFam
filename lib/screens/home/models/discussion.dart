class Discussion {
  final String id;
  final String title; // e.g., "Medicinal use of microorganisms"
  final String path; // e.g., "Science → Microorganisms"
  final int durationMin; // e.g., 8
  final List<String> badges; // e.g., ["IN CLASS","TEST TUE"]

  const Discussion({
    required this.id,
    required this.title,
    required this.path,
    required this.durationMin,
    this.badges = const [],
  });
}
