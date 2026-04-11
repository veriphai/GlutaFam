import 'package:flutter/material.dart';
import '../models/home_data_models.dart';
import 'journey_card.dart';

class JourneyList extends StatelessWidget {
  final List<JourneyData> journeys;
  final Function(JourneyData) onJourneyTap;

  const JourneyList({
    super.key,
    required this.journeys,
    required this.onJourneyTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: journeys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => JourneyCard(
        journey: journeys[i],
        onTap: () => onJourneyTap(journeys[i]),
      ),
    );
  }
}
