// Ember — ui/widgets/ember_button.dart
//
// Shared kid-friendly controls. Large hit areas (>= 48px), chunky rounded
// shapes, warm palette, tactile press scale. Self-contained: reads the palette
// directly, never the host app's widgets. Three flavours cover the module's
// needs: a primary ember button, a soft secondary, and an icon-glyph round
// button. Everything else (HUD chips, codex cards) composes from EmberUi.

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';
import '../ember_theme.dart';

/// Visual emphasis for [EmberButton].
enum EmberButtonStyle { primary, secondary, danger, ghost }

/// A big, friendly tappable button with a press-scale animation.
class EmberButton extends StatefulWidget {
  const EmberButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = EmberButtonStyle.primary,
    this.expand = false,
    this.palette = EmberPalette.dusk,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EmberButtonStyle style;

  /// Stretch to the parent width.
  final bool expand;
  final EmberPalette palette;

  bool get enabled => onPressed != null;

  @override
  State<EmberButton> createState() => _EmberButtonState();
}

class _EmberButtonState extends State<EmberButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = widget.palette;
    final (Color bg, Color fg, Color border) = switch (widget.style) {
      EmberButtonStyle.primary => (p.ember, Colors.white, p.emberDeep),
      EmberButtonStyle.secondary => (p.surfaceRaised, p.ink, p.outline),
      EmberButtonStyle.danger => (p.danger, Colors.white, p.emberDeep),
      EmberButtonStyle.ghost => (Colors.transparent, p.ink, p.outline),
    };
    final double opacity = widget.enabled ? 1.0 : 0.45;

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            Icon(widget.icon, color: fg, size: 22),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _down = false) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(EmberUi.radius),
              border: Border.all(color: border, width: 2),
              boxShadow: widget.style == EmberButtonStyle.ghost
                  ? const <BoxShadow>[]
                  : <BoxShadow>[
                      BoxShadow(
                        color: p.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// A round icon button with a generous tap target.
class EmberIconButton extends StatelessWidget {
  const EmberIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 48,
    this.palette = EmberPalette.dusk,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final EmberPalette palette;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final Widget button = Material(
      color: background ?? palette.surface,
      shape: CircleBorder(
        side: BorderSide(color: palette.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: foreground ?? palette.ink, size: size * 0.5),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
