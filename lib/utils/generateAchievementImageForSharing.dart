import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:eureka_app/utils/achievements.dart';

Future<String?> generateAchievementImage(BuildContext context,
    Map<String, dynamic> achievement, int levelCriteria) async {
  try {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 🔥 High-resolution scaling
    final double imageSize = 1200.0;
    final Paint paint = Paint();

    // 🔲 Draw Background (Black)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize, imageSize),
      paint..color = Colors.blue,
    );

    // 📌 Load Achievement Image
    final String assetPath = getAchievement(achievement["id"])?["imagePath"] ??
        'lib/assets/placeholder.png';

    final ui.Image? uiImage = await loadAssetImage(assetPath);

    if (uiImage != null) {
      final srcRect = Rect.fromLTWH(
        0,
        0,
        uiImage.width.toDouble(),
        uiImage.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(
        imageSize * 0.16,
        imageSize * 0.05,
        imageSize * 0.66,
        imageSize * 0.66,
      );

      // 🖼 Draw Image (Make sure this is under text)
      canvas.drawImageRect(uiImage, srcRect, dstRect, paint);
    } else {
      print("Error: Could not load achievement image");
    }

    // ✅ Ensure text is stacked on top of image
    final double textSize = imageSize * 0.2;

    // 🔠 Draw Level Text - Outline Effect (First, draw stroke)
// 🔠 Draw Level Text - Outline Effect (First, draw stroke)
    final TextPainter outlinePainter = TextPainter(
      text: TextSpan(
        text: "$levelCriteria",
        style: TextStyle(
          fontSize: textSize,
          fontWeight: FontWeight.w700,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = textSize * 0.2 // Outline thickness
            ..color = achievement["unlocked"]
                ? const Color.fromARGB(255, 159, 129, 81) // Gold outline
                : Colors.grey, // Locked outline
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center, // Align text center
    );
    outlinePainter.layout();

// 🏹 Dynamically Center the Text Horizontally
    final double textX = (imageSize - outlinePainter.width) / 2;
    final double textY = imageSize * 0.52; // Adjust Y position if needed

// Draw Outline First
    outlinePainter.paint(canvas, Offset(textX, textY));

// 🔠 Draw Level Text - Filled Effect (On top of stroke)
    final TextPainter filledPainter = TextPainter(
      text: TextSpan(
        text: "$levelCriteria",
        style: TextStyle(
          fontSize: textSize,
          fontWeight: FontWeight.w700,
          color: achievement["unlocked"] ? Colors.white : Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    filledPainter.layout();

// 🏹 Center the Filled Text Same as Outline
    final double filledTextX = (imageSize - filledPainter.width) / 2;
    filledPainter.paint(canvas, Offset(filledTextX, textY));

    // 1️⃣ "I earned the {achievement name} achievement"
    final TextPainter achievementTextPainter = TextPainter(
      text: TextSpan(
        text: "I earned the ${achievement["name"]} achievement",
        style: TextStyle(
          fontSize: imageSize * 0.06, // Slightly smaller
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2, // ✅ Allow up to 2 lines
      ellipsis: '...', // Optional: Add "..." if text is too long
    );
    achievementTextPainter.layout(
      maxWidth: imageSize * 0.8, // ✅ Restrict width to ensure wrapping
    );

// 🏹 Center "I earned the achievement" Text
    final double achievementTextX =
        (imageSize - achievementTextPainter.width) / 2;
    final double achievementTextY = imageSize * 0.75; // Below image
    achievementTextPainter.paint(
        canvas, Offset(achievementTextX, achievementTextY));

    // 2️⃣ "Glutaclass" branding
    final TextPainter glutaclassPainter = TextPainter(
      text: TextSpan(
        text: "Glutaclass",
        style: TextStyle(
          fontSize: imageSize * 0.08, // Larger branding text
          fontWeight: FontWeight.w900,
          color: Colors.yellow, // Branding color
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    glutaclassPainter.layout();

    // 🏹 Center "Glutaclass"
    final double glutaclassTextX = (imageSize - glutaclassPainter.width) / 2;
    final double glutaclassTextY =
        imageSize * 0.9; // Below the achievement text
    glutaclassPainter.paint(canvas, Offset(glutaclassTextX, glutaclassTextY));

    // 📷 Convert to High-Resolution Image
    final picture = recorder.endRecording();
    final ui.Image finalImage =
        await picture.toImage(imageSize.toInt(), imageSize.toInt());

    final ByteData? byteData =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List buffer = byteData!.buffer.asUint8List();

    // 💾 Save High-Quality Image to Temporary Directory
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = '${tempDir.path}/achievement_share.png';
    final File file = File(filePath);
    await file.writeAsBytes(buffer);

    return filePath;
  } catch (e) {
    print("Error generating image: $e");
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
