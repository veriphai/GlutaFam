class SearchableConcept {
  final String conceptName;
  final String topicName;
  final String chapterName;
  final String subject;
  final int standard;

  SearchableConcept({
    required this.conceptName,
    required this.topicName,
    required this.chapterName,
    required this.subject,
    required this.standard,
  });

  Map<String, String> toMap() {
    return {
      'conceptName': conceptName,
      'topicName': topicName,
      'chapterName': chapterName,
      'subject': subject,
    };
  }
}

class SearchableChapter {
  final String chapterName;
  final String subject;
  final int standard;

  SearchableChapter({
    required this.chapterName,
    required this.subject,
    required this.standard,
  });
}

class SearchableTopic {
  final String topicName;
  final String chapterName;
  final String subject;
  final int standard;

  SearchableTopic({
    required this.topicName,
    required this.chapterName,
    required this.subject,
    required this.standard,
  });
}
