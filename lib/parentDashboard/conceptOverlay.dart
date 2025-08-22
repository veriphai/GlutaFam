import 'package:eureka_app/parentDashboard/checkpointCard.dart';
import 'package:eureka_app/parentDashboard/gapCard.dart';
import 'package:eureka_app/parentDashboard/masteryStrip.dart';
import 'package:eureka_app/parentDashboard/models.dart';
import 'package:eureka_app/parentDashboard/shiningCard.dart';
import 'package:flutter/material.dart';

class ConceptOverlay {
  static void show(BuildContext context, String conceptId,
      Map<String, ConceptDetailsModel> all) {
    final details = all[conceptId];
    if (details == null) return;
    final meta = details.meta;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.85;
        final isWide = MediaQuery.of(ctx).size.width >= 900;
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH, maxWidth: 1100),
            child: Column(
              children: [
                // Sticky header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).cardColor.withOpacity(0.95),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          offset: const Offset(0, 1),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meta.concept,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${meta.subject} • ${meta.chapter}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              if (meta.desc.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(meta.desc),
                                ),
                            ]),
                      ),
                      IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close)),
                    ],
                  ),
                ),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Gaps + Shining moments side by side
                        LayoutBuilder(builder: (c, box) {
                          final twoCol = box.maxWidth >= 820;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: twoCol
                                    ? (box.maxWidth - 16) / 2
                                    : box.maxWidth,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Gaps',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      const SizedBox(height: 6),
                                      ...details.gaps
                                          .map((g) => GapCard(gap: g)),
                                    ]),
                              ),
                              SizedBox(
                                width: twoCol
                                    ? (box.maxWidth - 16) / 2
                                    : box.maxWidth,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Shining moments',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      const SizedBox(height: 6),
                                      ...details.shining
                                          .map((s) => ShiningCard(moment: s)),
                                    ]),
                              ),
                            ],
                          );
                        }),

                        const SizedBox(height: 20),
                        // Mastery improvement (no box)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: MasteryStrip(mastery: details.mastery),
                        ),

                        const SizedBox(height: 16),
                        // Resolve plan (simple card for affordance)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Resolve plan',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text('Talk: ${details.plan.talk}'),
                                const SizedBox(height: 4),
                                Text(
                                    'Mini-drill: ${details.plan.drillIds.join(', ')}'),
                                const SizedBox(height: 4),
                                Text('Real-life: ${details.plan.realLife}'),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, children: [
                                  FilledButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.share, size: 16),
                                      label: const Text('Send WhatsApp')),
                                  OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.phone_android,
                                          size: 16),
                                      label: const Text(
                                          'Start on child’s device')),
                                  TextButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(
                                          Icons.bookmark_add_outlined,
                                          size: 16),
                                      label: const Text('Save for weekend')),
                                ]),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Checkpoint-wise details toggle
                        _CheckpointSection(details: details),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CheckpointSection extends StatefulWidget {
  final ConceptDetailsModel details;
  const _CheckpointSection({required this.details});

  @override
  State<_CheckpointSection> createState() => _CheckpointSectionState();
}

class _CheckpointSectionState extends State<_CheckpointSection> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final cps = widget.details.checkpointDetails;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: () => setState(() => open = !open),
          child: Text(open
              ? 'Hide checkpoint-wise details'
              : 'View checkpoint-wise details'),
        ),
        if (open)
          LayoutBuilder(builder: (c, box) {
            final twoCol = box.maxWidth >= 820;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: cps
                  .map((cp) => SizedBox(
                        width: twoCol ? (box.maxWidth - 16) / 2 : box.maxWidth,
                        child: CheckpointCard(cp: cp),
                      ))
                  .toList(),
            );
          }),
      ],
    );
  }
}
