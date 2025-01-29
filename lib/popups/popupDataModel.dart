import 'package:eureka_app/popups/popUpType.dart';
import 'package:flutter/material.dart';

class PopupData {
  final PopupType type;
  final String title;
  final String description;
  final String image;
  final VoidCallback? onAction;

  PopupData({
    required this.type,
    required this.title,
    required this.description,
    required this.image,
    this.onAction,
  });
}
