import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool checkIsWebOnDesktop(BuildContext context) {
  if (!kIsWeb) {
    return false; // Not running on web
  }

  // Check if the screen width exceeds a typical mobile width threshold
  final double screenWidth = MediaQuery.of(context).size.width;
  return screenWidth >= 600; // Adjust this breakpoint for your needs
}