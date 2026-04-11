import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/app_colors.dart';

class HomeSearchButton extends StatelessWidget {
  final VoidCallback onTap;
  final FocusNode? searchFocusNode;

  const HomeSearchButton({
    super.key,
    required this.onTap,
    this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        // For iOS, also try to request focus immediately after state change
        if (!kIsWeb && Platform.isIOS && searchFocusNode != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (searchFocusNode!.canRequestFocus) {
                searchFocusNode!.requestFocus();
              }
            });
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.searchBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.searchBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 18,
              color: AppColors.sub,
            ),
            const SizedBox(width: 8),
            Text(
              "Search lessons, chapters, topics",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.sub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
