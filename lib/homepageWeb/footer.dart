import 'package:flutter/material.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return constrained(
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Container(
          decoration: panelDecoration(),
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.cyan]),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Tuto',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.text)),
              const Spacer(),
              Text(
                  '© ${DateTime.now().year} Tuto — Built for parents who want clarity, not surprises.',
                  style:
                      const TextStyle(color: AppColors.subtext, fontSize: 12)),
              const Spacer(),
              Row(children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Privacy',
                      style: TextStyle(color: AppColors.subtext)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child:
                      Text('Terms', style: TextStyle(color: AppColors.subtext)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
