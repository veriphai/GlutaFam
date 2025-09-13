import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// SearchBar with notebook-style yellow highlighter swash behind it.
/// - Leading search icon
/// - Trailing mic & camera actions
/// - Focus glow + stronger border when active
class NotebookSearchField extends StatefulWidget {
  const NotebookSearchField({
    super.key,
    required this.onSubmit,
    this.onChanged,
    this.onMic,
    this.onCamera,
    this.controller,
    this.focusNode,
    this.hintText = "Search any topic",
    this.highlighterColor =
        const Color.fromRGBO(253, 233, 137, 1), // marker yellow
    this.paperColor = const Color(0xFFFFF7E3), // paper cream
  });

  final ValueChanged<String> onSubmit;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMic;
  final VoidCallback? onCamera;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;

  final Color highlighterColor;
  final Color paperColor;

  @override
  State<NotebookSearchField> createState() => _NotebookSearchFieldState();
}

class _NotebookSearchFieldState extends State<NotebookSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  bool get _hasFocus => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const inkBlue = Color(0xFF1E4B7A);
    const borderColor = Color.fromRGBO(195, 186, 154, 1); // beige line
    final activeBorder = inkBlue;
    const _inkMuted = Color.fromRGBO(48, 52, 47, 1);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Yellow highlighter swash (slightly larger than the input)

        // Input container
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: widget.paperColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hasFocus ? activeBorder : borderColor,
              width: 2,
            ),
            boxShadow: [
              if (_hasFocus)
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              else
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // const SizedBox(width: 6),

              // HIGHLIGHTED CLUSTER: search icon + textfield + mic
              Expanded(
                child: Container(
                  // margin: const EdgeInsets.symmetric(
                  //     vertical: 6), // lets the cream show around
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      // center = full yellow, edges = yellow blended toward paper
                      colors: [
                        Color.lerp(
                            widget.paperColor, widget.highlighterColor, 0.55)!,
                        Color.lerp(widget.paperColor, widget.highlighterColor,
                            0.55)!, // left light
                        widget.highlighterColor
                            .withOpacity(0.95), // center strong
                        Color.lerp(widget.paperColor, widget.highlighterColor,
                            0.55)!, // right light
                        Color.lerp(
                            widget.paperColor, widget.highlighterColor, 0.55)!,
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ), // <-- yellow swash
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ), // slightly smaller than outer
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: widget.onSubmit,
                          onChanged: widget.onChanged,
                          textInputAction: TextInputAction.search,
                          cursorColor: const Color(0xFF1E4B7A),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            hintStyle: GoogleFonts.kalam(
                                color: _inkMuted,
                                height: 1.1,
                                fontSize: 22,
                                fontWeight: FontWeight.w500),
                          ),
                          style: GoogleFonts.kalam(
                              color: _inkMuted,
                              height: 1.1,
                              fontSize: 22,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      _IconButtonBare(
                        icon: Icons.mic_none,
                        onTap: widget.onMic,
                        size: 25,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // CAMERA sits outside the yellow group
              _IconButtonBare(
                icon: Icons.search,
                onTap: widget.onCamera,
                size: 35,
              ),

              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrailingIconButton extends StatelessWidget {
  const _TrailingIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const inkBlue = Color(0xFF1E4B7A);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: inkBlue, size: 22),
          ),
        ),
      ),
    );
  }
}

class _IconButtonBare extends StatelessWidget {
  const _IconButtonBare({required this.icon, this.onTap, required this.size});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    const inkBlue = Color.fromRGBO(61, 61, 52, 1);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: Icon(icon, color: inkBlue, size: size)),
        ),
      ),
    );
  }
}
