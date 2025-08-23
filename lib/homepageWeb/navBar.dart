import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class NavBar extends StatelessWidget {
  final void Function(String id) onNav; // 👈 new

  const NavBar({super.key, required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppLayout.sectionPadding(context),
      decoration: const BoxDecoration(
        color: Color(0x660B1220),
        // subtle blur-like
      ),
      child: constrained(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [AppColors.teal, AppColors.cyan],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withOpacity(.25),
                      blurRadius: 18,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text('Tuto',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      fontSize: 16)),
            ]),
            Row(children: [
              _NavLink('Why Tuto', 'value', onTap: onNav),
              _NavLink('How it works', 'how', onTap: onNav),
              _NavLink('FAQs', 'faq', onTap: onNav),
            ]),
            Row(children: [
              OutlinedButton(
                  onPressed: () {},
                  style: ghostBtn,
                  child: const Text('See a demo')),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: () {},
                  style: primaryBtn,
                  child: const Text('Run today’s free check')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final String id; // e.g. 'faq'
  final void Function(String id) onTap;
  const _NavLink(this.label, this.id, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: () => onTap(id),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: const TextStyle(color: AppColors.subtext)),
        ),
      ),
    );
  }
}
