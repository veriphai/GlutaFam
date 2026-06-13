// Small reusable building blocks shared across the homepage:
// entrance animation, idle floating, press feedback, glass surfaces, etc.

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'careerTheme.dart';

/// Fades + slides a child up once, after an optional [delay]. Used to stagger
/// sections/cards in on first load.
class RevealOnLoad extends StatefulWidget {
  const RevealOnLoad({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 18,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<RevealOnLoad> createState() => _RevealOnLoadState();
}

class _RevealOnLoadState extends State<RevealOnLoad> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * widget.offsetY), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Gently bobs a child up and down forever (satellites, robots, badges).
class Floaty extends StatefulWidget {
  const Floaty({
    super.key,
    required this.child,
    this.amplitude = 5,
    this.period = const Duration(milliseconds: 2600),
    this.phase = 0,
  });

  final Widget child;
  final double amplitude;
  final Duration period;
  final double phase;

  @override
  State<Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final dy = math.sin((_c.value * 2 * math.pi) + widget.phase) * widget.amplitude;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

/// Scales the child down slightly while pressed, then fires [onTap].
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.onTap, this.pressedScale = 0.96});

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Translucent "glass" surface with a soft border. [blur] turns on a real
/// BackdropFilter (used sparingly: stat pills, bottom nav).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = CareerRadii.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.color = CareerColors.glassFill,
    this.borderColor = CareerColors.glassBorder,
    this.blur = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
    if (!blur) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: content,
      ),
    );
  }
}

/// "⭐ Title ............ View All >" row used above each section.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.emoji,
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 7),
        Expanded(child: Text(title, style: CareerText.sectionTitle)),
        PressableScale(
          onTap: onAction,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(actionLabel,
                style: CareerText.body.copyWith(color: CareerColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, size: 16, color: CareerColors.textPrimary),
          ]),
        ),
      ],
    );
  }
}

/// Glass back-button + "emoji Title / subtitle" header used by the catalog
/// subpages (All Jobs, All Worlds). Mirrors the profession-detail app bar so
/// every pushed screen shares one navigation language.
class SubpageAppBar extends StatelessWidget {
  const SubpageAppBar({
    super.key,
    required this.title,
    this.emoji,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? emoji;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PressableScale(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CareerColors.glassFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CareerColors.glassBorder),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (emoji != null) ...[
                    Text(emoji!, style: const TextStyle(fontSize: 17)),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CareerColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Centered glass pill closing the catalog lists ("more coming soon") so
/// locked content reads as a promise rather than a dead end.
class ComingSoonFooter extends StatelessWidget {
  const ComingSoonFooter({super.key, required this.emoji, required this.message});

  final String emoji;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: CareerColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small labelled icon chip (skill tags on the hero card).
class SkillChip extends StatelessWidget {
  const SkillChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: CareerColors.glassFillStrong,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: CareerColors.glassBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: CareerColors.cyan),
        const SizedBox(width: 3),
        Text(label, style: CareerText.chip.copyWith(fontSize: 8.5)),
      ]),
    );
  }
}

/// Circular icon badge with a coloured glow — used on cards and the passport.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 14, spreadRadius: 1)],
      ),
      child: Icon(icon, size: size * 0.5, color: Colors.white),
    );
  }
}

/// Small "locked" badge — a circular glass chip with a white lock icon,
/// layered on top of any gated card. Pair with a semi-transparent black
/// scrim over the card's existing content to communicate the disabled state.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.lock_rounded, size: size * 0.55, color: Colors.white),
    );
  }
}

/// Loads [asset] as a decoration image, falling back to a gradient placeholder
/// (so the layout looks right before real illustrations exist).
class IllustrationPanel extends StatelessWidget {
  const IllustrationPanel({
    super.key,
    required this.gradient,
    this.asset,
    this.borderRadius,
    this.child,
  });

  final List<Color> gradient;
  final String? asset;
  final BorderRadius? borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final String? a = asset;
    // Network URL (http*) → NetworkImage; bundled path → AssetImage. Lets a
    // backend-supplied illustration (e.g. WOW-concept card art on S3) ride the
    // same full-bleed slot as a bundled profession asset.
    final DecorationImage? bg = (a == null || a.isEmpty)
        ? null
        : DecorationImage(
            image: a.startsWith('http') ? NetworkImage(a) : AssetImage(a) as ImageProvider,
            fit: BoxFit.cover,
            onError: (_, __) {}, // silently fall back to the gradient
          );
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        image: bg,
      ),
      child: child,
    );
  }
}
