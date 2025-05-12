import 'dart:io';
import 'dart:ui' as ui;
import 'package:eureka_app/utils/avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:typed_data';

Future<String?> generateProfileCard(
    BuildContext context, Map<String, dynamic> profile) async {
  try {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 🔥 High-resolution scaling
    final double imageSize = 1200.0;
    final Paint paint = Paint();

    // 🔲 Draw Background (Blue)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize, imageSize),
      paint..color = Colors.white,
    );

    // 🎨 Define Border Properties
    final double borderPadding = imageSize * 0.04; // Border thickness
    final Color borderColor = Colors.blue.shade200; // Change to desired color

    // 📌 Load Profile Avatar
    final String assetPath = getAvatar(profile["avatar"])["imagePath"] ??
        'lib/assets/placeholder.png';
    final ui.Image? uiImage = await loadAssetImage(assetPath);

    final double blueBoxHeight = imageSize * 0.7; // Adjust height as needed
    final double blueBoxWidth =
        imageSize * 0.9; // Width should be smaller than the canvas width
    final double blueBoxX = (imageSize - blueBoxWidth) / 2; // Centering logic
    final double blueBoxY = 60;

    final double cornerRadius =
        imageSize * 0.05; // Adjust corner radius as needed

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(blueBoxX, blueBoxY, blueBoxWidth, blueBoxHeight),
        Radius.circular(cornerRadius),
      ),
      paint..color = Colors.blue.shade200, // Blue box color
    );

    // 📌 Load Profile Avatar

    if (uiImage != null) {
      final double avatarSize =
          blueBoxHeight * 1; // Adjust avatar size relative to the blue box

      // 🖼 Draw Avatar (Centered in the Blue Box)
      final double avatarX = (imageSize - avatarSize) / 2; // Centering logic
      final double avatarY = blueBoxY + (blueBoxHeight - avatarSize) / 2;

      final Rect imageRect =
          Rect.fromLTWH(avatarX, avatarY, avatarSize, avatarSize);
      final srcRect = Rect.fromLTWH(
          0, 0, uiImage.width.toDouble(), uiImage.height.toDouble());
      canvas.drawImageRect(uiImage, srcRect, imageRect, paint);
    } else {
      print("Error: Could not load profile avatar");
    }

    // 🏷️ Draw Name
    final TextPainter nameTextPainter = TextPainter(
      text: TextSpan(
        text: "${profile["firstName"]}",
        style: TextStyle(
          fontSize: imageSize * 0.06,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '...',
    );
    nameTextPainter.layout(maxWidth: imageSize * 0.8);
    final double nameTextY = imageSize * 0.8;
    nameTextPainter.paint(canvas, Offset(blueBoxX, nameTextY));

    // 🏷️ Draw Username
    final TextPainter userNameTextPainter = TextPainter(
      text: TextSpan(
        text: "@${profile["userName"]}",
        style: TextStyle(
          fontSize: imageSize * 0.04,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '...',
    );
    userNameTextPainter.layout(maxWidth: imageSize * 0.8);
    final double userNameTextY = imageSize * 0.88;
    userNameTextPainter.paint(canvas, Offset(blueBoxX, userNameTextY));

    final ui.Image? logoImage =
        await loadAssetImage("lib/assets/tuto-logo.png");

    if (logoImage != null) {
      final double logoSize = imageSize * 0.15;
      final double logoX = blueBoxX + blueBoxWidth - logoSize;
      final double logoY = nameTextY;

      final Rect logoRect = Rect.fromLTWH(logoX, logoY, logoSize, logoSize);
      final Rect srcRect = Rect.fromLTWH(
          0, 0, logoImage.width.toDouble(), logoImage.height.toDouble());
      canvas.drawImageRect(logoImage, srcRect, logoRect, paint);
    }

    // 📷 Convert to High-Resolution Image
    final picture = recorder.endRecording();
    final ui.Image finalImage =
        await picture.toImage(imageSize.toInt(), imageSize.toInt());

    final ByteData? byteData =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List buffer = byteData!.buffer.asUint8List();

    // 💾 Save High-Quality Image to Temporary Directory
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = '${tempDir.path}/profile_card.png';
    final File file = File(filePath);
    await file.writeAsBytes(buffer);

    return filePath;
  } catch (e) {
    print("Error generating profile card: $e");
    return null;
  }
}

/// ✅ **Helper function to load an image from assets**
Future<ui.Image?> loadAssetImage(String assetPath) async {
  try {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  } catch (e) {
    print("Error loading asset image: $e");
    return null;
  }
}
