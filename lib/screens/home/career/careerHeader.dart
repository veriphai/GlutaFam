// Top header — single row: child avatar + greeting (2-line subtitle),
// compact XP / Badges / Streak stat pills, and a notification bell.
//
// All fields are optional and fall back to demo values so the screen still
// renders pre-API (debug-skip) or while the home bundle is loading.

import 'package:flutter/material.dart';
import 'careerCommon.dart';
import 'careerTheme.dart';

class CareerHeader extends StatelessWidget {
  const CareerHeader({
    super.key,
    this.name,
    this.xp,
    this.badges,
    this.streakDays,
  });

  /// Greeting name. Defaults to a neutral "Friend" when no profile is loaded.
  final String? name;

  /// Header stats — fall back to demo numbers when null so the layout never
  /// shows zeros to the user before the home bundle resolves.
  final int? xp;
  final int? badges;
  final int? streakDays;

  @override
  Widget build(BuildContext context) {
    final greeting = 'Hi ${name?.trim().isNotEmpty == true ? name!.trim() : 'Friend'}! 👋';
    // ignore: unused_local_variable
    final xpStr = (xp ?? 1250).toString();
    // ignore: unused_local_variable
    final badgesStr = (badges ?? 12).toString();
    final streakStr = (streakDays ?? 7).toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _Avatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(greeting,
                  style: CareerText.greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('What amazing job will you try today?',
                  style: CareerText.subtitle.copyWith(color: CareerColors.textMuted, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // XP + Badges pills hidden for now — uncomment when the XP/badge
        // earning model is live. The Day Streak pill stays since streaks
        // already increment server-side on each lesson completion.
        // _StatPill(iconEmoji: '⭐', value: xpStr, label: 'XP', labelColor: CareerColors.gold),
        // const SizedBox(width: 6),
        // _StatPill(
        //   iconWidget: const Icon(Icons.shield_rounded, size: 15, color: CareerColors.purple),
        //   value: badgesStr,
        //   label: 'Badges',
        // ),
        // const SizedBox(width: 6),
        _StatPill(iconEmoji: '🔥', value: streakStr, label: 'Day Streak'),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FD0FF), Color(0xFF4A90D9)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
        boxShadow: [BoxShadow(color: CareerColors.blue.withValues(alpha: 0.35), blurRadius: 10)],
        image: const DecorationImage(
          image: AssetImage('assets/images/avatar.png'),
          fit: BoxFit.cover,
          onError: _ignore,
        ),
      ),
      alignment: Alignment.center,
      child: const Text('🧒', style: TextStyle(fontSize: 26)),
    );
  }

  static void _ignore(Object e, StackTrace? s) {}
}

// iconWidget + labelColor on _StatPill are temporarily unreferenced
// because the Badges + XP pills (their only callers) are commented out
// in the header build above. Keep both params so re-enabling those pills
// is a one-line uncomment instead of widening the ctor again.
// ignore_for_file: unused_element_parameter

class _StatPill extends StatelessWidget {
  const _StatPill({
    this.iconEmoji,
    this.iconWidget,
    required this.value,
    required this.label,
    this.labelColor,
  });

  final String? iconEmoji;
  final Widget? iconWidget;
  final String value;
  final String label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 16,
      blur: true,
      padding: const EdgeInsets.fromLTRB(8, 5, 9, 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            iconWidget ?? Text(iconEmoji ?? '', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(value, style: CareerText.statValue),
          ]),
          const SizedBox(height: 1),
          Text(label, style: CareerText.statLabel.copyWith(color: labelColor ?? CareerColors.textSecondary)),
        ],
      ),
    );
  }
}
