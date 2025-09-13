import 'package:eureka_app/screens/home/models/discussion.dart';
import 'package:eureka_app/screens/home/models/recommendedTab.dart';
import 'package:eureka_app/screens/home/widgets/recommended/discussionRow.dart';
import 'package:eureka_app/screens/home/widgets/recommended/discussionRowCard.dart';
import 'package:eureka_app/screens/home/widgets/recommended/featuredDiscussionCard.dart';
import 'package:eureka_app/screens/home/widgets/recommended/recommendedTabsBar.dart';
import 'package:eureka_app/screens/home/widgets/recommended/recommendedTray.dart';
import 'package:flutter/material.dart';

class RecommendedSection extends StatefulWidget {
  const RecommendedSection({
    super.key,
    required this.tabs,
    required this.discussions,
    this.initialTabId,
    this.onSelectTab,
    this.onStartDiscussion,
  });

  final List<RecommendedTab> tabs;
  final List<Discussion> discussions;
  final String? initialTabId;
  final ValueChanged<String>? onSelectTab;
  final ValueChanged<String>? onStartDiscussion;

  @override
  State<RecommendedSection> createState() => _RecommendedSectionState();
}

class _RecommendedSectionState extends State<RecommendedSection> {
  late String _selectedTabId = widget.initialTabId ??
      (widget.tabs.isNotEmpty ? widget.tabs.first.id : "");
  String? _expandedId; // which discussion is featured

  List<Discussion> get _filtered {
    // Simple filter: by tab label prefix in path; adjust to your subject keying
    return widget.discussions
        .where(
            (d) => d.path.toLowerCase().contains(_selectedTabId.toLowerCase()))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  void initState() {
    super.initState();
    final f = _filtered;
    if (f.isNotEmpty) _expandedId = f.first.id; // first expanded by default
  }

  void _onSelectTab(String id) {
    setState(() {
      _selectedTabId = id;
      final f = _filtered;
      _expandedId = f.isNotEmpty ? f.first.id : null;
    });
    widget.onSelectTab?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final expanded = filtered.isNotEmpty
        ? filtered.firstWhere((d) => d.id == _expandedId,
            orElse: () => filtered.first)
        : null;
    const double kTabHeight = 50; // must match RecommendedTabsBar.tabHeight
    const double kTabsOverlapTop = kTabHeight / 2 - 15; // half in, half out

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(left: 4, right: 14, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Color.fromRGBO(248, 236, 201, 1), // sticky note yellow
            // borderRadius: BorderRadius.circular(10),
            border: const Border(
              bottom: BorderSide(
                  color: Color.fromRGBO(216, 203, 161, 1), width: 1.5),
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            "Recommended Discussions:",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color.fromRGBO(48, 52, 47, 1)),
          ),
        ),

        const SizedBox(height: 16),

        // Tabs (overlapped)
        Padding(
            padding: const EdgeInsets.only(top: kTabsOverlapTop),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // TRAY (everything lives inside this)
                SizedBox(
                  width: double.infinity, // <-- key: stretch horizontally
                  child: RecommendedTray(
                    padding: const EdgeInsets.fromLTRB(
                        8, kTabsOverlapTop + kTabHeight, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (expanded != null)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: FeaturedDiscussionCard(
                              key: ValueKey(expanded.id),
                              item: expanded,
                              onStart: () =>
                                  widget.onStartDiscussion?.call(expanded.id),
                            ),
                          ),

                        const SizedBox(height: 12),
                        for (final d
                            in filtered.where((e) => e.id != _expandedId))
                          DiscussionRowCard(
                            key: ValueKey("row_${d.id}"),
                            item: d,
                            onTapExpand: () =>
                                setState(() => _expandedId = d.id),
                            onStart: () => widget.onStartDiscussion?.call(d.id),
                          ),
                        // SizedBox(height: 160), // LIST placeholder
                      ],
                    ),
                  ),
                ),

                // TABS: half in/half out, centered horizontally
                Positioned(
                  top: -kTabsOverlapTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      height:
                          kTabHeight, // must match RecommendedTabsBar.tabHeight
                      child: RecommendedTabsBar(
                        tabs: widget.tabs,
                        selectedId: _selectedTabId,
                        onSelect: _onSelectTab,
                        tabHeight: kTabHeight,
                        overlapPx: 12,
                      ),
                    ),
                  ),
                ),
              ],
            )),

        const SizedBox(height: 12),

        // Featured (expanded one) — switches when a row is tapped

        const SizedBox(height: 12),

        // The list (collapsed rows). Tapping any row expands it above.
      ],
    );
  }
}
