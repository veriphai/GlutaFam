// Floating glass bottom navigation. Home / Worlds / Profile.
// The selected tab gets a glowing blue pill; the rest are muted.
// Items are Expanded + FittedBox so they can never overflow at narrow widths.

import 'package:flutter/material.dart';
import 'careerCommon.dart';
import 'careerTheme.dart';

class CareerBottomNav extends StatefulWidget {
  const CareerBottomNav({super.key, this.onSelect});

  /// Fired with the tapped tab label (e.g. 'Play') so the host can navigate.
  final void Function(String label)? onSelect;

  @override
  State<CareerBottomNav> createState() => _CareerBottomNavState();
}

class _CareerBottomNavState extends State<CareerBottomNav> {
  int _index = 0;

  static const List<(IconData, String)> _items = [
    (Icons.home_rounded, 'Home'),
    // (Icons.sports_esports_rounded, 'Play'),    // hidden for now — the
    //   activities demo screen stays reachable in code (ActivitiesScreen).
    (Icons.public_rounded, 'Worlds'),
    // (Icons.menu_book_rounded, 'Passport'),     // hidden until the
    //   passport feature ships.
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: GlassSurface(
        radius: 28,
        blur: true,
        color: const Color(0x40101B3D),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavItem(
                  icon: _items[i].$1,
                  label: _items[i].$2,
                  selected: i == _index,
                  onTap: () {
                    // Push-style tabs (Play, Worlds, …) open a screen ON TOP
                    // of home, so don't move the persistent highlight — Home
                    // is still what's underneath when the user pops back.
                    if (_items[i].$2 == 'Home') setState(() => _index = i);
                    widget.onSelect?.call(_items[i].$2);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : CareerColors.textMuted;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.92,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CareerRadii.pill),
            gradient: selected ? const LinearGradient(colors: [CareerColors.blue, CareerColors.purple]) : null,
            boxShadow: selected ? [BoxShadow(color: CareerColors.blue.withValues(alpha: 0.5), blurRadius: 14)] : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 6),
              Text(label, style: CareerText.navLabel.copyWith(color: color)),
            ]),
          ),
        ),
      ),
    );
  }
}
