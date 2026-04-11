import 'dart:async';
import 'package:manim_web/manim.dart';

/// Test scene for rendering LaTeX expressions with Manim Web
/// This demonstrates various mathematical formulas and text rendering capabilities
class LatexTestScene extends Scene {
  @override
  FutureOr<void> preload() {
    // Preload all LaTeX expressions that will be used in the scene

    // Simple text
    Tex.preload('Hello from Manim Web!');

    // Quadratic formula
    MathTex.preload(r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}');

    // Pythagorean theorem
    MathTex.preload(r'a^2 + b^2 = c^2');

    // Euler's identity
    MathTex.preload(r'e^{i\pi} + 1 = 0');

    // Summation
    MathTex.preload(r'\sum_{i=1}^{n} i = \frac{n(n+1)}{2}');

    // Integration
    MathTex.preload(r'\int_{0}^{\infty} e^{-x^2} dx = \frac{\sqrt{\pi}}{2}');

    // Trigonometry
    MathTex.preload(r'\sin^2(\theta) + \cos^2(\theta) = 1');

    // Matrix
    MathTex.preload(r'\begin{bmatrix} a & b \\ c & d \end{bmatrix}');
  }

  @override
  FutureOr<void> construct() async {
    // Test 1: Simple text with LaTeX
    var welcomeText = Tex('Hello from Manim Web!');
    welcomeText.scaleUniformly(2);

    await play(FadeIn(welcomeText));
    await wait(1);
    await play(FadeOut(welcomeText));

    // Test 2: Quadratic Formula
    var quadraticFormula = MathTex(r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}');
    quadraticFormula.scaleUniformly(2);

    await play(ShowCreation(quadraticFormula));
    await wait(2);
    await play(FadeOut(quadraticFormula));

    // Test 3: Pythagorean Theorem
    var pythagorean = MathTex(r'a^2 + b^2 = c^2');
    pythagorean.scaleUniformly(3);

    await play(FadeIn(pythagorean));
    await wait(2);
    await play(FadeOut(pythagorean));

    // Test 4: Euler's Identity
    var euler = MathTex(r'e^{i\pi} + 1 = 0');
    euler.scaleUniformly(2.5);

    await play(ShowCreation(euler));
    await wait(2);
    await play(FadeOut(euler));

    // Test 5: Summation Formula
    var summation = MathTex(r'\sum_{i=1}^{n} i = \frac{n(n+1)}{2}');
    summation.scaleUniformly(2);

    await play(FadeIn(summation));
    await wait(2);
    await play(FadeOut(summation));

    // Test 6: Integration
    var integration =
        MathTex(r'\int_{0}^{\infty} e^{-x^2} dx = \frac{\sqrt{\pi}}{2}');
    integration.scaleUniformly(1.8);

    await play(ShowCreation(integration));
    await wait(2);
    await play(FadeOut(integration));

    // Test 7: Trigonometry
    var trig = MathTex(r'\sin^2(\theta) + \cos^2(\theta) = 1');
    trig.scaleUniformly(2.5);

    await play(FadeIn(trig));
    await wait(2);
    await play(FadeOut(trig));

    // Test 8: Matrix
    var matrix = MathTex(r'\begin{bmatrix} a & b \\ c & d \end{bmatrix}');
    matrix.scaleUniformly(3);

    await play(ShowCreation(matrix));
    await wait(2);
    await play(FadeOut(matrix));

    // Final message
    var endText = Tex('LaTeX Test Complete!');
    endText.scaleUniformly(2.5);

    await play(FadeIn(endText));
    await wait(2);
  }
}

/// Simple test scene with just one formula
class SimpleLatexTest extends Scene {
  @override
  FutureOr<void> preload() {
    MathTex.preload(r'E = mc^2');
  }

  @override
  FutureOr<void> construct() async {
    var einstein = MathTex(r'E = mc^2');
    einstein.scaleUniformly(4);

    await play(FadeIn(einstein));
    await wait(2);
  }
}

/// Interactive visual graph scene with shapes and animations
class InteractiveGraphScene extends Scene {
  @override
  FutureOr<void> preload() {
    // Preload LaTeX for equations and labels
    MathTex.preload(r'Interactive Math Visualization');
    MathTex.preload(r'y = x^2');
    MathTex.preload(r'y = \sin(x)');
    Tex.preload('Circle');
    Tex.preload('Square');
  }

  @override
  FutureOr<void> construct() async {
    // Title
    var title = MathTex(r'Interactive Math Visualization');
    title.scaleUniformly(1.8);

    await play(FadeIn(title));
    await wait(0.8);
    await play(FadeOut(title));

    // Create a number plane (coordinate system)
    var plane = NumberPlane();
    plane.scaleUniformly(0.5);

    await play(ShowCreation(plane));
    await wait(0.5);

    // Create geometric shapes
    var circle = Circle();
    circle.shift(LEFT * 2);

    var square = Square();
    square.shift(RIGHT * 2);

    // Add labels
    var circleLabel = Tex('Circle');
    circleLabel.scaleUniformly(0.7);
    circleLabel.shift(LEFT * 2 + DOWN * 2);

    var squareLabel = Tex('Square');
    squareLabel.scaleUniformly(0.7);
    squareLabel.shift(RIGHT * 2 + DOWN * 2);

    // Animate shapes appearing
    await play(ShowCreation(circle));
    await play(FadeIn(circleLabel));
    await wait(0.3);

    await play(ShowCreation(square));
    await play(FadeIn(squareLabel));
    await wait(1);

    // Show mathematical functions
    var equation1 = MathTex(r'y = x^2');
    equation1.scaleUniformly(1.2);
    equation1.shift(UP * 2 + LEFT * 3);

    await play(FadeIn(equation1));
    await wait(1);

    var equation2 = MathTex(r'y = \sin(x)');
    equation2.scaleUniformly(1.2);
    equation2.shift(UP * 2 + RIGHT * 3);

    await play(FadeIn(equation2));
    await wait(2);
  }
}

/// Animated shapes scene
class ShapesAnimationScene extends Scene {
  @override
  FutureOr<void> preload() {
    MathTex.preload(r'Geometric Shapes');
    MathTex.preload(r'\triangle \square \bigcirc');
  }

  @override
  FutureOr<void> construct() async {
    // Title
    var title = MathTex(r'Geometric Shapes');
    title.scaleUniformly(2);

    await play(FadeIn(title));
    await wait(1);
    await play(FadeOut(title));

    // Create shapes
    var circle1 = Circle();
    circle1.shift(LEFT * 3);

    var circle2 = Circle();
    circle2.shift(ORIGIN);

    var circle3 = Circle();
    circle3.shift(RIGHT * 3);

    // Animate all appearing at once
    await playMany([
      ShowCreation(circle1),
      ShowCreation(circle2),
      ShowCreation(circle3),
    ]);

    await wait(1);

    // Create squares inside
    var square1 = Square();
    square1.shift(LEFT * 3);
    square1.scaleUniformly(0.7);

    var square2 = Square();
    square2.shift(ORIGIN);
    square2.scaleUniformly(0.7);

    var square3 = Square();
    square3.shift(RIGHT * 3);
    square3.scaleUniformly(0.7);

    await playMany([
      ShowCreation(square1),
      ShowCreation(square2),
      ShowCreation(square3),
    ]);

    await wait(1);

    // Show formula
    var formula = MathTex(r'\triangle \square \bigcirc');
    formula.shift(DOWN * 2.5);
    formula.scaleUniformly(2);

    await play(FadeIn(formula));
    await wait(2);
  }
}

const resolution = 3;

class FourierScene extends Scene {
  late Axes timeAxes;
  late Axes frequencyAxes;
  late NumberPlane circlePlane;
  late DashedVMobject dashedCircle;
  late SurroundingRectangle frequencyBox;
  late Dot centerOfMass;
  late Dot fourierDot;
  late FunctionGraph fourierGraph;
  late FunctionGraph wave;
  late ParametricFunction polarized;
  late VMobject partialFourierGraph;

  double windingFrequency = 0;

  @override
  FutureOr<void> preload() {
    MathTex.preload(r'\hat{g}(f) = \int^{+\infty}_{-\infty} g(t)'
        r' e^{-2 \pi ift} dt');
  }

  @override
  Future construct() async {
    await addWaveWithAxes();
    windingFrequency = 5;
    await addPolarizedWaveWithAxes();

    addFrequencyAxes();
    await playMany([FadeIn(frequencyAxes), FadeIn(frequencyBox)]);
    fourierGraph = getFourierGraph(wave);

    await addDots();
    await showFourierGraphCreation();
    await addFormula();

    makeInteractive();

    await continueRendering();
  }

  Future addFormula() async {
    var tex = MathTex(r'\hat{g}(f) = \int^{+\infty}_{-\infty} g(t)'
        r' e^{-2 \pi ift} dt')
      ..toCorner(corner: UR)
      ..scaleUniformly(1.2);
    await play(ShowCreation(tex));
  }

  Future addAllAxes() async {
    addCirclePlane();
    addFrequencyAxes();
    await play(FadeIn(circlePlane));
    await play(FadeIn(frequencyAxes));
  }

  Future addDots() async {
    partialFourierGraph = VMobject()
      ..setFill(color: TRANSPARENT)
      ..setPoints([fourierGraph.getEnd()]);
    centerOfMass = Dot(ORIGIN)..setColor(color: RED_C);
    fourierDot = Dot(fourierGraph.getEnd())..setColor(color: RED_C);

    centerOfMass
        .addUpdater((dot, dt) => dot..moveToPoint(polarized.getCenterOfMass()));

    await play(FadeIn(centerOfMass));
    await play(FadeIn(fourierDot));

    fourierDot.addUpdater(fourierDotCreationUpdater);
  }

  Mobject fourierDotCreationUpdater(Mobject dot, double dt) =>
      dot..moveToPoint(partialFourierGraph.getStart());

  Future showFourierGraphCreation() async {
    addToFront([fourierDot, partialFourierGraph]);

    partialFourierGraph.addUpdater((graph, dt) =>
        graph..pointwiseBecomePartial(fourierGraph, windingFrequency / 5, 1));

    await play(getFrequencyChangeAnimation(wave, polarized, 5, 2, runTime: 12));
    await play(getFrequencyChangeAnimation(wave, polarized, 2, 0, runTime: 10));

    remove([partialFourierGraph]);
    add([fourierGraph]);
  }

  Future addWaveWithAxes() async {
    addTimeAxes();
    // wave = getCosineWave(shiftVal: 0, scaleVal: 1.8); // positive and negative
    wave = getCosineWave(); // positive only
    await play(FadeIn(timeAxes));
    await play(ShowCreation(wave));
  }

  Future addPolarizedWaveWithAxes() async {
    addCirclePlane();
    var polarizedTarget = getPolarizedMobject(wave, windingFrequency);
    polarized = wave.copy();
    await play(FadeIn(circlePlane));
    await play(Transform(polarized, target: polarizedTarget));
  }

  void makeInteractive() {
    fourierDot.removeUpdater(fourierDotCreationUpdater);

    var draggableDot = DraggableMobject(mob: fourierDot);
    draggableDot.addUpdater(draggableDotOnFunctionUpdater);

    add([draggableDot]);
  }

  Mobject draggableDotOnFunctionUpdater(Mobject dot, double dt) {
    var coords = frequencyAxes.pointToCoords(fourierDot.getPos());
    var x = clip(coords.x, 0, 5).toDouble();
    var y = fourierGraph.getValueFromFunction(x);
    var pt = frequencyAxes.c2p(Vector3(x, y, 0));
    fourierDot.moveToPoint(pt);

    windingFrequency = x;
    polarized.become(getPolarizedMobject(wave, x));

    return dot;
  }

  FunctionGraph getFourierGraph(FunctionGraph wave) {
    return frequencyAxes.getGraph((x) => getFourierTransform(x, wave).real,
        stepSize: 0.05 / resolution);
  }

  Complex getFourierTransform(double x, ParametricFunction wave,
      {bool useAlmostFourierTransform = true}) {
    var anchors = wave.getAnchors();

    var _polarizePoint = (Vector3 pt, double freq) {
      var coords = timeAxes.pointToCoords(pt);

      var t = coords.x;
      var y = coords.y;

      var z = Complex.exp(angle: -TAU * freq * t) * Complex.fromDouble(y);

      return z;
    };

    var polarizedPoints = [for (var pt in anchors) _polarizePoint(pt, x)];

    // TODO When the fft function will be working properly, use the code bellow
    // var coords = [for (var pt in anchors) timeAxes.p2c(pt)];
    // var values = [for (var c in coords) c.y];

    // var polarizedPoints = fft(values);

    var scalar = Complex.fromDouble(
        useAlmostFourierTransform ? 1 / polarizedPoints.length : 1);

    return polarizedPoints.reduce((a, b) => a + b) * scalar;
  }

  Axes addTimeAxes() {
    timeAxes = Axes(
      xMin: 0,
      xMax: 4.4,
      yMin: -1,
      yMax: 2.5,
      xAxisConfig: AxisConfig(
        tickFrequency: 0.25,
        numbersWithElongatedTicks: [0, 1, 2, 3, 4],
        unitSize: 2,
      ),
      yAxisConfig: AxisConfig(
        unitSize: 0.5,
        numbersWithElongatedTicks: [],
      ),
      axisConfig: AxisConfig(
        includeTip: true,
      ),
    )
      ..setColor(color: LIGHT_GREY)
      ..toCorner(corner: UL);

    // TODO Add labels

    return timeAxes;
  }

  NumberPlane addCirclePlane() {
    circlePlane = NumberPlane(xMin: -2.1, yMin: -2.1, yMax: 2.1, xMax: 2.1)
      ..scaleUniformly(0.8)
      ..toCorner(corner: DL);

    dashedCircle = Circle().getDashed(numDashes: 50)
      ..setStroke(width: DEFAULT_STROKE_WIDTH / 2)
      ..scaleUniformly(0.8)
      ..shift(circlePlane.coordsToPoint(ORIGIN));

    circlePlane.addToFront([dashedCircle]);

    return circlePlane;
  }

  Axes addFrequencyAxes() {
    frequencyAxes = Axes(
      axisConfig: AxisConfig(color: TEAL_C),
      xMin: 0,
      xMax: 5,
      xAxisConfig:
          AxisConfig(unitSize: 1, numbersToShow: range(start: 1, end: 6)),
      yMin: -1,
      yMax: 1,
      yAxisConfig:
          AxisConfig(unitSize: 1.4, tickFrequency: 0.5, labelDirection: LEFT),
    )..setColor(color: TEAL_C);

    frequencyAxes.nextToMobject(circlePlane, direction: RIGHT);
    frequencyBox =
        SurroundingRectangle(mobject: frequencyAxes, buff: MED_SMALL_BUFFER)
          ..setStroke(color: TEAL_C);

    // TODO add labels

    return frequencyAxes;
  }

  FunctionGraph getTimeGraph(double Function(double) func,
      [double stepSize = 0.05 / resolution]) {
    return timeAxes.getGraph(func, stepSize: stepSize)
      ..setStroke(color: YELLOW_C)
      ..setFill(color: TRANSPARENT);
  }

  FunctionGraph getCosineWave(
          {List<double> frequencies = const [2],
          double shiftVal = 1,
          double scaleVal = 0.9,
          double stepSize = 0.05 / resolution}) =>
      getTimeGraph(
          (t) =>
              shiftVal +
              scaleVal *
                  sum([for (var freq in frequencies) cos(TAU * t * freq)]),
          stepSize);

  Mobject getPolarizedMobject(Mobject mob, double windingFrequency) {
    var polarizedMobject = mob.copy();
    polarizedMobject.applyFunction((pt) => polarizePoint(pt, windingFrequency));
    return polarizedMobject;
  }

  Vector3 polarizePoint(Vector3 pt, double windingFrequency) {
    var coords = timeAxes.pointToCoords(pt);

    var t = coords.x;
    var y = coords.y;

    var z =
        Complex.exp(angle: -TAU * windingFrequency * t) * Complex.fromDouble(y);

    return circlePlane.coordsToPoint(z.toVector3());
  }

  UpdateFromFunc getPolarizedAnimation(
      Mobject mobject, double windingFrequency) {
    var polarized = getPolarizedMobject(mobject, windingFrequency);

    return UpdateFromFunc(
        mobject: polarized,
        updateFunc: (mob) {
          Transform(mob, target: getPolarizedMobject(mobject, windingFrequency))
              .update(1);
          return mob;
        });
  }

  Future animateFrequencyChange(List<Tuple2<Mobject, Mobject>> mobjects,
      double startWindingFrequency, double newWindingFrequency,
      {double runTime = 3, List<Animation> addedAnimations = const []}) async {
    await playMany([
      for (var mob in mobjects)
        getFrequencyChangeAnimation(
            mob.item1, mob.item2, startWindingFrequency, newWindingFrequency),
      ...addedAnimations
    ]);
  }

  UpdateFromAlphaFunc getFrequencyChangeAnimation(
      Mobject mobject,
      Mobject polarized,
      double startWindingFrequency,
      double newWindingFrequency,
      {double runTime = 3}) {
    return UpdateFromAlphaFunc(
        mobject: polarized,
        updateFunc: (pm, alpha) {
          var freq =
              interpolate(startWindingFrequency, newWindingFrequency, alpha);
          windingFrequency = freq;

          var newPm = getPolarizedMobject(mobject, freq);

          pm.become(newPm);

          return pm;
        },
        runTime: runTime);
  }
}

class MatrixTransformationScene extends Scene {
  late Array transformationMatrix;
  late NumberPlane plane;
  late NumberPlane fadedPlane;
  late NumberPlane originalPlane;
  late Dot i;
  late Dot j;
  late Dot originalI;
  late Dot originalJ;
  late Arrow arrowI;
  late Arrow arrowJ;
  late MathTex texI;
  late MathTex texJ;
  late MathTex texMatrix;

  double planeScale = 1.5;

  @override
  FutureOr<void> preload() {
    MathTex.preload(r'\hat{\imath}');
    MathTex.preload(r'\hat{\jmath}');
  }

  @override
  Future construct() async {
    transformationMatrix = Array.identity(2);

    await createPlane();
    await createControls();
    await addTexMatrix();
    await transformPlane([
      [0, -1],
      [1, 0]
    ]); // rotation on 90 degrees
    await transformPlane([
      [1, 0.5],
      [0, 1]
    ]); // sheer along x
    makeInteractive();
    await continueRendering();
  }

  Future createPlane() async {
    var planeRadius = max(FRAME_X_RADIUS, FRAME_Y_RADIUS);

    originalPlane = NumberPlane(
        xMin: -planeRadius * planeScale,
        xMax: planeRadius * planeScale,
        yMin: -planeRadius * planeScale,
        yMax: planeRadius * planeScale,
        makeSmoothAfterApplyingFunctions: false);
    plane = originalPlane.copy();

    await play(AnimationGroup([
      for (var submob in plane.getFamily())
        if (submob.hasPoints()) ShowCreation(submob),
    ], lagRatio: 0.01));
  }

  Future createControls() async {
    originalI = Dot(originalPlane.c2p(RIGHT))..setColor(color: RED_C);
    originalJ = Dot(originalPlane.c2p(UP))..setColor(color: GREEN_C);

    var originPoint = originalPlane.c2p(ORIGIN);

    i = originalI.copy();
    j = originalJ.copy();

    arrowI = Arrow(start: originPoint, end: i.getPos(), buff: 0)
      ..setColor(color: RED_C);
    arrowJ = Arrow(start: originPoint, end: j.getPos(), buff: 0)
      ..setColor(color: GREEN_C);

    addTex();

    addToFront([i, j, arrowI, arrowJ, texI, texJ]);
    await play(AnimationGroup([
      for (var mob in [i, j, arrowI, arrowJ]) ShowCreation(mob),
      for (var tex in [texI, texJ]) FadeIn(tex)
    ], lagRatio: 0.1));
  }

  void addTex() {
    texI = MathTex(r'\hat{\imath}')
      ..setColor(color: RED_C)
      ..addUpdater(
          (m, dt) => m..nextToMobject(i, direction: UL, buffer: SMALL_BUFFER));
    texJ = MathTex(r'\hat{\jmath}')
      ..setColor(color: GREEN_C)
      ..addUpdater(
          (m, dt) => m..nextToMobject(j, direction: UL, buffer: SMALL_BUFFER));
  }

  Future addTexMatrix() async {
    // Tex substring isolation isn't possible yet
    // TODO Change that
    // texMatrix = MathTex('''
    //   \\begin{bmatrix}
    //     {{1.00}} & {{0.00}}    \\\\
    //     {{0.00}} & {{1.00}}
    //   \\end{bmatrix}
    // ''');

    // texMatrix.addUpdater((_, dt) => texMatrix
    //   ..content = '''
    //   \\begin{bmatrix}
    //     ${transformationMatrix[Tuple2(0, 0)]} & ${transformationMatrix[Tuple2(0, 1)]}    \\\\
    //     ${transformationMatrix[Tuple2(1, 0)]} & ${transformationMatrix[Tuple2(1, 1)]}
    //   \\end{bmatrix}
    // ''');

    // await play(FadeIn(texMatrix));
  }

  Future transformPlane(List<List<double>> values) async {
    var matrix = Array(values: values);

    // assert values is a 2x2 matrix
    assert(listEqual(matrix.shape.toList(), [2, 2]));

    var p2 = plane.copy()..applyMatrix(matrix);

    transformationMatrix = matrix.matMul(transformationMatrix);

    var iPos = originalPlane.c2p(RIGHT).matMul(transformationMatrix);
    var jPos = originalPlane.c2p(UP).matMul(transformationMatrix);

    // update the position of i and j
    var i2 = i.copy()..moveToPoint(iPos);
    var j2 = j.copy()..moveToPoint(jPos);

    var originPoint = originalPlane.c2p(ORIGIN);
    var newArrowI = Arrow(start: originPoint, end: iPos, buff: 0)
      ..setColor(color: RED_C);
    var newArrowJ = Arrow(start: originPoint, end: jPos, buff: 0)
      ..setColor(color: GREEN_C);

    await playMany([
      Transform(i, target: i2),
      Transform(j, target: j2),
      Transform(arrowI, target: newArrowI),
      Transform(arrowJ, target: newArrowJ),
      Transform(plane, target: p2),
    ]);
  }

  void makeInteractive() {
    add([DraggableMobject(mob: i), DraggableMobject(mob: j)]);

    var planeUpdater = (Mobject mob, double dt) {
      var iPos = originalPlane.p2c(i.getCenter());
      var jPos = originalPlane.p2c(j.getCenter());

      var newPlane = originalPlane.copy()
        ..applyMatrix(Array(values: [
          [iPos.x, jPos.x],
          [iPos.y, jPos.y]
        ]));

      var originPoint = originalPlane.c2p(ORIGIN);
      var newArrowI = Arrow(start: originPoint, end: iPos, buff: 0)
        ..setColor(color: RED_C);
      var newArrowJ = Arrow(start: originPoint, end: jPos, buff: 0)
        ..setColor(color: GREEN_C);

      plane.become(newPlane);
      arrowI.become(newArrowI);
      arrowJ.become(newArrowJ);
      return mob;
    };

    i.addUpdater(planeUpdater);
    j.addUpdater(planeUpdater);
  }
}

Vector3 listToVector(List<double> l) =>
    l.length == 2 ? Vector3(l[0], l[1], 0) : Vector3(l[0], l[1], l[2]);
