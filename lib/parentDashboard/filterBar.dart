import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final String studentLabel;
  final List<String> subjects;
  final String selectedSubject;
  final ValueChanged<String> onSubject;
  final String datePreset; // Today | 7d | 30d | Custom
  final ValueChanged<String> onPreset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final ValueChanged<DateTime?> onCustomStart;
  final ValueChanged<DateTime?> onCustomEnd;

  const FilterBar({
    super.key,
    required this.studentLabel,
    required this.subjects,
    required this.selectedSubject,
    required this.onSubject,
    required this.datePreset,
    required this.onPreset,
    required this.customStart,
    required this.customEnd,
    required this.onCustomStart,
    required this.onCustomEnd,
  });

  Future<void> _pickDate(BuildContext context, DateTime? initial,
      ValueChanged<DateTime?> onPick) async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    onPick(res);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 12,
      spacing: 24,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(studentLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(width: 12),
        DropdownColumn(
          label: 'Subject',
          value: selectedSubject,
          items: subjects,
          onChanged: onSubject,
        ),
        DropdownColumn(
          label: 'Date',
          value: datePreset,
          items: const ['Today', '7d', '30d', 'Custom'],
          onChanged: onPreset,
        ),
        if (datePreset == 'Custom') ...[
          DatePickColumn(
            label: 'Start',
            date: customStart,
            onTap: (c) => _pickDate(c, customStart, onCustomStart),
          ),
          DatePickColumn(
            label: 'End',
            date: customEnd,
            onTap: (c) => _pickDate(c, customEnd, onCustomEnd),
          ),
        ],
      ],
    );
  }
}

class DropdownColumn extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const DropdownColumn(
      {super.key,
      required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: DropdownButton<String>(
            value: value,
            onChanged: (v) => v != null ? onChanged(v) : null,
            items: items
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class DatePickColumn extends StatelessWidget {
  final String label;
  final DateTime? date;
  final void Function(BuildContext) onTap;
  const DatePickColumn(
      {super.key,
      required this.label,
      required this.date,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final txt = date == null
        ? 'Pick date'
        : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: () => onTap(context),
            icon: const Icon(Icons.event, size: 16),
            label: Text(txt),
          ),
        ),
      ],
    );
  }
}
