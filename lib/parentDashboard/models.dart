class Student {
  final String name;
  final String grade;
  Student({required this.name, required this.grade});
}

class FeedGroup {
  final DateTime date;
  final List<ConceptSummary> items;
  FeedGroup({required this.date, required this.items});
}

class ConceptSummary {
  final String id;
  final String subject;
  final String chapter;
  final String concept;
  final int gapsFound;
  final String oneLiner;
  final double mastery; // 0..1
  final double confidence; // 0..1
  ConceptSummary({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.concept,
    required this.gapsFound,
    required this.oneLiner,
    required this.mastery,
    required this.confidence,
  });
}

class GapDetails {
  final String tutorAsk;
  final String studentText;
  final List<TimelineEvent> timeline;
  GapDetails(
      {required this.tutorAsk,
      required this.studentText,
      required this.timeline});
}

class TimelineEvent {
  final String t;
  final String? verdict; // "✅" | "❌"
  final String? hint;
  final String? text;
  TimelineEvent({required this.t, this.verdict, this.hint, this.text});
}

class Gap {
  final String id;
  final String type; // Conceptual | Careless | Vocab | Units
  final int severity; // 1..3
  final String why;
  final GapDetails details;
  final String resolvePlanId;
  Gap(
      {required this.id,
      required this.type,
      required this.severity,
      required this.why,
      required this.details,
      required this.resolvePlanId});
}

class ShiningMoment {
  final String id;
  final String wow;
  final String quote;
  ShiningMoment({required this.id, required this.wow, required this.quote});
}

class Mastery {
  final double start, end;
  final List<double> checkpoints;
  Mastery({required this.start, required this.end, required this.checkpoints});
}

class ResolvePlan {
  final String talk;
  final List<String> drillIds;
  final String realLife;
  ResolvePlan(
      {required this.talk, required this.drillIds, required this.realLife});
}

class CheckpointDetails {
  final String id;
  final List<String> objectives;
  final double mastery;
  final List<Gap> gaps;
  final List<ShiningMoment> shining;
  CheckpointDetails(
      {required this.id,
      required this.objectives,
      required this.mastery,
      required this.gaps,
      required this.shining});
}

class ConceptMeta {
  final String subject;
  final String chapter;
  final String concept;
  final String desc;
  ConceptMeta(
      {required this.subject,
      required this.chapter,
      required this.concept,
      required this.desc});
}

class ConceptDetailsModel {
  final ConceptMeta meta;
  final List<Gap> gaps;
  final List<ShiningMoment> shining;
  final Mastery mastery;
  final ResolvePlan plan;
  final List<CheckpointDetails> checkpointDetails;
  ConceptDetailsModel({
    required this.meta,
    required this.gaps,
    required this.shining,
    required this.mastery,
    required this.plan,
    required this.checkpointDetails,
  });
}
