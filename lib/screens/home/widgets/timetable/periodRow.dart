import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../../models/period.dart';

class PeriodRow extends StatelessWidget {
  const PeriodRow({
    super.key,
    required this.period,
    required this.isCurrent,
    this.showBottomRule = true,
    this.minHeight = 20, // uniform row height
    this.timeRailWidth = 36,
  });

  final Period period;
  final bool isCurrent;
  final bool showBottomRule;
  final double minHeight;
  final double timeRailWidth;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);
  static const _marker = Color(0xFFF7E07A);
  static const _muted = Color.fromRGBO(48, 52, 47, 1);

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Give the row a finite height to avoid infinite constraints.
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // <-- was stretch
            children: [
              // Time rail
              SizedBox(
                width: timeRailWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_fmt(period.start),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: _muted,
                          fontWeight: FontWeight.w600,
                        ))
                    // Text(_fmt(period.start),
                    //     style: const TextStyle(
                    //       fontSize: 12.5,
                    //       fontFeatures: [FontFeature.tabularFigures()],
                    //       color: _muted,
                    //       fontWeight: FontWeight.w600,
                    //     )),
                    // Text('-${_fmt(period.end)}',
                    //     style: const TextStyle(
                    //       fontSize: 12.5,
                    //       fontFeatures: [FontFeature.tabularFigures()],
                    //       color: _muted,
                    //       fontWeight: FontWeight.w600,
                    //     )),
                  ],
                ),
              ),

              // Subject cell
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCurrent ? _marker.withOpacity(0.65) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EEF7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _trayLine, width: 1),
                        ),
                        child: const Icon(Icons.science_outlined,
                            size: 18, color: _inkBlue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              period.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _muted,
                                height: 1.05,
                              ),
                            ),
                            Text(
                              period.topic,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: period.accent,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (showBottomRule)
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 1,
            color: _trayLine.withOpacity(0.9),
          ),
      ],
    );
  }
}
