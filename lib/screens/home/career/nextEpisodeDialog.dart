// "Episode complete → here's what's next" celebration modal, shown when a
// lesson finishes and the chain has a next (now-unlocked) episode.
//
// showNextEpisodeDialog(...) returns true when the user taps "Start" (the
// caller launches the next lesson) and false/null on "Go Back" / dismiss
// (the caller just stays on the Your Path page, already refreshed).
//
// Premium career-theme card: gradient border, episode thumbnail, title +
// short description, the "You'll Discover" hook and reward, Start (gold,
// primary) + Go Back (quiet, secondary).

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'careerTheme.dart';
import 'professionDetailModels.dart';

Future<bool> showNextEpisodeDialog(
  BuildContext context, {
  required Lesson next,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'next-episode',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, _, __) => _NextEpisodeCard(next: next),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = Curves.easeOutBack.transform(anim.value.clamp(0.0, 1.0));
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim.value, sigmaY: 5 * anim.value),
        child: Opacity(
          opacity: anim.value,
          child: Transform.scale(scale: 0.9 + 0.1 * curved, child: child),
        ),
      );
    },
  );
  return result == true;
}

class _NextEpisodeCard extends StatelessWidget {
  const _NextEpisodeCard({required this.next});

  final Lesson next;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 330,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: CareerGradients.heroBorder,
            boxShadow: [
              BoxShadow(
                color: CareerColors.purple.withValues(alpha: 0.45),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.4),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF18244F), Color(0xFF0B1028)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Celebratory eyebrow.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      'EPISODE COMPLETE',
                      style: GoogleFonts.poppins(
                        color: CareerColors.gold,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _thumbnail(),
                const SizedBox(height: 14),
                Text(
                  'UP NEXT · EPISODE ${next.number}',
                  style: GoogleFonts.poppins(
                    color: CareerColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  next.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: CareerColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                if ((next.longDescription ?? next.shortDescription).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    next.longDescription?.isNotEmpty == true
                        ? next.longDescription!
                        : next.shortDescription,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: CareerColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
                if ((next.discoverHook ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _infoLine(
                    icon: Icons.auto_awesome_rounded,
                    color: CareerColors.cyan,
                    label: "You'll discover",
                    body: next.discoverHook!,
                  ),
                ],
                if ((next.rewardName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoLine(
                    icon: Icons.military_tech_rounded,
                    color: CareerColors.gold,
                    label: 'Reward',
                    body: next.rewardName!,
                  ),
                ],
                const SizedBox(height: 20),
                _startButton(context),
                const SizedBox(height: 2),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(
                      color: CareerColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final art = next.thumbnailAsset;
    final accent = next.thumbnailColor ?? CareerColors.purple;
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.55),
            Color.lerp(accent, Colors.black, 0.55)!,
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 20),
        ],
        image: art != null
            ? DecorationImage(
                image: art.startsWith('http')
                    ? NetworkImage(art)
                    : AssetImage(art) as ImageProvider,
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
            : null,
      ),
      alignment: Alignment.center,
      child: art == null
          ? Icon(next.thumbnailIcon, size: 42, color: Colors.white)
          : null,
    );
  }

  Widget _infoLine({
    required IconData icon,
    required Color color,
    required String label,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label:  ',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: body,
                  style: GoogleFonts.poppins(
                    color: CareerColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _startButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: CareerGradients.gold,
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(color: CareerColors.gold.withValues(alpha: 0.4), blurRadius: 16),
          ],
        ),
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CareerRadii.pill),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Start Episode ${next.number}',
                style: GoogleFonts.poppins(
                  color: CareerColors.onLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.play_arrow_rounded,
                  color: CareerColors.onLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
