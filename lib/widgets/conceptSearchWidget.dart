import 'package:eureka_app/models/searchableConcept.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:google_fonts/google_fonts.dart';

class ConceptSearchBar extends StatefulWidget {
  final List<Map<String, dynamic>> chapterJson;
  final void Function(SearchableConcept) onSelect;

  const ConceptSearchBar({
    super.key,
    required this.chapterJson,
    required this.onSelect,
  });

  @override
  State<ConceptSearchBar> createState() => _ConceptSearchBarState();
}

class _ConceptSearchBarState extends State<ConceptSearchBar> {
  late List<SearchableConcept> allConcepts;

  final TextEditingController _controller = TextEditingController();
  late List<SearchableChapter> chapterList;
  late List<SearchableTopic> topicList;
  late List<SearchableConcept> conceptList;

  late Fuzzy<SearchableChapter> chapterFuse;
  late Fuzzy<SearchableTopic> topicFuse;
  late Fuzzy<SearchableConcept> conceptFuse;

  List<SearchableChapter> matchedChapters = [];
  List<SearchableTopic> matchedTopics = [];
  List<SearchableConcept> matchedConcepts = [];

  void _flattenAll() {
    final chapters = widget.chapterJson;

    final ch = <SearchableChapter>{};
    final tp = <SearchableTopic>{};
    final cp = <SearchableConcept>[];

    for (final chapter in chapters) {
      final chapterName = chapter['name'];
      final subject = chapter['subject'];
      final standard = int.tryParse(chapter['standard'].toString()) ?? 0;

      ch.add(SearchableChapter(
        chapterName: chapterName,
        subject: subject,
        standard: standard,
      ));

      for (final topic in chapter['topics']) {
        final topicName = topic['name'];

        tp.add(SearchableTopic(
          topicName: topicName,
          chapterName: chapterName,
          subject: subject,
          standard: standard,
        ));

        for (final lesson in topic['lessons']) {
          cp.add(SearchableConcept(
            conceptName: lesson['name'],
            topicName: topicName,
            chapterName: chapterName,
            subject: subject,
            standard: standard,
          ));
        }
      }
    }

    chapterList = ch.toList();
    topicList = tp.toList();
    conceptList = cp;
  }

  @override
  void initState() {
    super.initState();
    _flattenAll();
    chapterFuse = Fuzzy(
      chapterList,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'chapterName',
            getter: (item) => item.chapterName,
            weight: 1.0,
          ),
          WeightedKey(
            name: 'subject',
            getter: (item) => item.subject,
            weight: 0.4,
          )
        ],
        threshold: 0.2,
      ),
    );

    topicFuse = Fuzzy(
      topicList,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'topicName',
            getter: (item) => item.topicName,
            weight: 1.0,
          ),
          WeightedKey(
            name: 'chapterName',
            getter: (item) => item.chapterName,
            weight: 0.6,
          ),
          WeightedKey(
            name: 'subject',
            getter: (item) => item.subject,
            weight: 0.4,
          )
        ],
        threshold: 0.2,
      ),
    );

    conceptFuse = Fuzzy(
      conceptList,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'conceptName',
            getter: (item) => item.conceptName,
            weight: 1.0,
          ),
          WeightedKey(
            name: 'topicName',
            getter: (item) => item.topicName,
            weight: 0.7,
          ),
          WeightedKey(
            name: 'chapterName',
            getter: (item) => item.chapterName,
            weight: 0.6,
          ),
        ],
        threshold: 0.4,
      ),
    );
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        matchedChapters = [];
        matchedTopics = [];
        matchedConcepts = [];
      });
      return;
    }

    // Chapter search
    final exactChapters = chapterList
        .where((c) => c.chapterName.toLowerCase().contains(q))
        .toList();
    final fuzzyChapters = chapterFuse.search(q).map((r) => r.item).toList();
    final allChapters = {
      for (var c in [...exactChapters, ...fuzzyChapters]) c.chapterName: c
    }.values.toList(); // remove duplicates

    // Topic search
    final exactTopics =
        topicList.where((t) => t.topicName.toLowerCase().contains(q)).toList();
    final fuzzyTopics = topicFuse.search(q).map((r) => r.item).toList();
    final allTopics = {
      for (var t in [...exactTopics, ...fuzzyTopics]) t.topicName: t
    }.values.toList();

    // Concept search
    final exactConcepts = conceptList
        .where((c) => c.conceptName.toLowerCase().contains(q))
        .toList();
    final fuzzyConcepts = conceptFuse.search(q).map((r) => r.item).toList();
    final allConcepts = {
      for (var c in [...exactConcepts, ...fuzzyConcepts]) c.conceptName: c
    }.values.toList();

    setState(() {
      matchedChapters = allChapters;
      matchedTopics = allTopics;
      matchedConcepts = allConcepts;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search by concept, topic, chapter...",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (matchedChapters.isEmpty &&
            matchedTopics.isEmpty &&
            matchedConcepts.isEmpty)
          const SizedBox.shrink()
        else
          Expanded(
            child: ListView(
              children: [
                if (matchedChapters.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "📘 Chapters",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  ...matchedChapters.map((c) => ListTile(
                        title: Text(c.chapterName,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text("${c.subject}",
                            style: const TextStyle(color: Colors.white70)),
                        onTap: () {
                          // TODO: Navigate to chapter detail
                        },
                      )),
                ],
                if (matchedTopics.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "🧩 Topics",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  ...matchedTopics.map((t) => ListTile(
                        title: Text(t.topicName,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text("${t.chapterName} • ${t.subject}",
                            style: const TextStyle(color: Colors.white70)),
                        onTap: () {
                          // TODO: Navigate to topic detail
                        },
                      )),
                ],
                if (matchedConcepts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "🔬 Concepts",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  ...matchedConcepts.map((c) => ListTile(
                        title: Text(c.conceptName,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                            "${c.topicName} • ${c.chapterName} • ${c.subject}",
                            style: const TextStyle(color: Colors.white70)),
                        onTap: () => widget.onSelect(c),
                      )),
                ],
              ],
            ),
          )
      ],
    );
  }
}
