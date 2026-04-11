import 'dart:async';
import 'package:manim_web/manim.dart';

/// Scene that displays a table with student data
class StudentTableScene extends Scene {
  @override
  FutureOr<void> preload() {
    // Preload table headers and sample data
    Tex.preload('Student Roll List');
    Tex.preload('Name');
    Tex.preload('Roll No.');
    Tex.preload('John Doe');
    Tex.preload('Jane Smith');
    Tex.preload('Alice Johnson');
    Tex.preload('Bob Wilson');
    Tex.preload('Charlie Brown');
    Tex.preload('001');
    Tex.preload('002');
    Tex.preload('003');
    Tex.preload('004');
    Tex.preload('005');
  }

  @override
  FutureOr<void> construct() async {
    // Title
    var title = Tex('Student Roll List');
    title.scaleUniformly(2);
    title.shift(UP * 3.5);

    await play(FadeIn(title));
    await wait(0.5);

    // Create table structure using rectangles and text
    var tableWidth = 8.0;
    var rowHeight = 0.8;

    // Headers
    var headerBg = Rectangle(
      width: tableWidth,
      height: rowHeight,
      color: BLUE,
    );
    headerBg.shift(UP * 2.4);

    var nameHeader = Tex('Name');
    nameHeader.shift(UP * 2.4 + LEFT * 2);
    nameHeader.scaleUniformly(0.8);

    var rollHeader = Tex('Roll No.');
    rollHeader.shift(UP * 2.4 + RIGHT * 2);
    rollHeader.scaleUniformly(0.8);

    await playMany([
      ShowCreation(headerBg),
      FadeIn(nameHeader),
      FadeIn(rollHeader),
    ]);

    await wait(0.5);

    // Sample student data
    final students = [
      ['John Doe', '001'],
      ['Jane Smith', '002'],
      ['Alice Johnson', '003'],
      ['Bob Wilson', '004'],
      ['Charlie Brown', '005'],
    ];

    // Create rows one by one with animation
    for (var i = 0; i < students.length; i++) {
      var yPos = 2.4 - ((i + 1) * rowHeight);

      // Row background
      var rowBg = Rectangle(
        width: tableWidth,
        height: rowHeight,
        color: i.isEven ? GREY : DARK_GREY,
      );
      rowBg.shift(UP * yPos);

      // Name
      var nameText = Tex(students[i][0]);
      nameText.shift(UP * yPos + LEFT * 2);
      nameText.scaleUniformly(0.6);

      // Roll number
      var rollText = Tex(students[i][1]);
      rollText.shift(UP * yPos + RIGHT * 2);
      rollText.scaleUniformly(0.6);

      // Animate row appearing
      await play(ShowCreation(rowBg));
      await playMany([
        FadeIn(nameText),
        FadeIn(rollText),
      ]);

      await wait(0.3);
    }

    await wait(2);

    // Add a "New Entry" animation
    var newEntryLabel = Tex('Adding new entry...');
    newEntryLabel.scaleUniformly(1.2);
    newEntryLabel.shift(DOWN * 3);

    await play(FadeIn(newEntryLabel));
    await wait(1);

    // Show the 6th row
    var yPos = 2.4 - (6 * rowHeight);
    var newRowBg = Rectangle(
      width: tableWidth,
      height: rowHeight,
      color: GREEN,
    );
    newRowBg.shift(UP * yPos);

    var newName = Tex('New Student');
    newName.shift(UP * yPos + LEFT * 2);
    newName.scaleUniformly(0.6);

    var newRoll = Tex('006');
    newRoll.shift(UP * yPos + RIGHT * 2);
    newRoll.scaleUniformly(0.6);

    await play(ShowCreation(newRowBg));
    await playMany([
      FadeIn(newName),
      FadeIn(newRoll),
    ]);

    await wait(2);
  }
}

/// Animated table with counting effect
class AnimatedTableScene extends Scene {
  @override
  FutureOr<void> preload() {
    Tex.preload('Student Database');
    Tex.preload('Total Students:');
    Tex.preload('Name');
    Tex.preload('Roll');
    MathTex.preload(r'Total: 5');
  }

  @override
  FutureOr<void> construct() async {
    var title = Tex('Student Database');
    title.scaleUniformly(2.5);

    await play(FadeIn(title));
    await wait(1);
    await play(FadeOut(title));

    // Create a simple visual table with rectangles
    var table = Group();

    // Draw grid
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 2; col++) {
        var cell = Rectangle(
          width: 3,
          height: 0.8,
          color: row == 0 ? BLUE : (row.isEven ? GREY : DARK_GREY),
        );
        cell.shift(
            LEFT * 1.5 + RIGHT * (col * 3) + UP * 2 + DOWN * (row * 0.8));
        table.add([cell]);
      }
    }

    await play(ShowCreation(table));

    // Headers
    var nameHeader = Tex('Name');
    nameHeader.shift(LEFT * 1.5 + UP * 2);
    nameHeader.scaleUniformly(0.7);

    var rollHeader = Tex('Roll');
    rollHeader.shift(RIGHT * 1.5 + UP * 2);
    rollHeader.scaleUniformly(0.7);

    await playMany([FadeIn(nameHeader), FadeIn(rollHeader)]);

    // Count indicator
    var counter = MathTex(r'Total: 5');
    counter.shift(DOWN * 3);
    counter.scaleUniformly(1.5);
    // counter.setColor(GREEN);

    await play(FadeIn(counter));
    await wait(2);
  }
}
