class Lesson {
  final String id;
  final String title; // e.g., "Why does yeast make dough rise?"
  final String path; // e.g., "Science → Microorganisms: Friend or Foe?"
  final int durationMin; // e.g., 8
  final double progress; // 0..1

  const Lesson({
    required this.id,
    required this.title,
    required this.path,
    required this.durationMin,
    this.progress = 0,
  });
}
