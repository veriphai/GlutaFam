// ONE chat bubble whose text swaps in lock-step with an OrbitVoiceThread:
// fade+slide OUT the old line, swap, fade+slide IN the new — the previous
// message disappears when the next appears (playbook: never AnimatedSwitcher
// cross-fade for voice-paced text — two lines collide visually and with the
// audio). An index with a null line hides the bubble (e.g. a clip narrating a
// static card). The last line stays visible after the thread ends.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/code_satellite_tuning.dart';
import 'chat_bubble.dart';

class VoicedBubble extends StatefulWidget {
  const VoicedBubble({
    super.key,
    required this.index,
    required this.lines,
    this.accents,
    this.fromRight = false,
    this.maxWidth = 2000,
  });

  /// The thread's `current` clip index.
  final ValueListenable<int> index;

  /// Text per clip index (null = no bubble while that clip plays).
  final List<String?> lines;

  /// Optional accent per clip index (defaults to cyan).
  final List<Color?>? accents;

  final bool fromRight;
  final double maxWidth;

  @override
  State<VoicedBubble> createState() => _VoicedBubbleState();
}

class _VoicedBubbleState extends State<VoicedBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  String? _text;
  Color _accent = CSColors.cyan;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    widget.index.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    widget.index.removeListener(_sync);
    _c.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    final gen = ++_gen;
    final i = widget.index.value;
    final text = (i >= 0 && i < widget.lines.length) ? widget.lines[i] : null;
    final accent =
        (widget.accents != null && i >= 0 && i < widget.accents!.length)
                ? (widget.accents![i] ?? CSColors.cyan)
                : CSColors.cyan;
    if (_text != null) await _c.reverse(); // old line OUT first
    if (!mounted || gen != _gen) return; // a newer line took over
    setState(() {
      _text = text;
      _accent = accent;
    });
    if (text != null) _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    if (text == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = Curves.easeOut.transform(_c.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child),
        );
      },
      child: ChatBubble(
        text: text,
        accent: _accent,
        fromRight: widget.fromRight,
        maxWidth: widget.maxWidth,
      ),
    );
  }
}
