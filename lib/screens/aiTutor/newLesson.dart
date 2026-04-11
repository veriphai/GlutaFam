import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

// To use sound effects, add this to your pubspec.yaml:
// dependencies:
//   audioplayers: ^6.5.1
//
// And run `flutter pub get`
import 'package:audioplayers/audioplayers.dart';

// --- Data Models ---
class LessonStep {
  final int id;
  final String type;
  final String narration;
  final String? formula;
  final String? keyLearning;
  final bool isMemo;
  final dynamic data;
  final String? hint;

  LessonStep({
    required this.id,
    required this.type,
    required this.narration,
    this.formula,
    this.keyLearning,
    this.isMemo = false,
    this.data,
    this.hint,
  });
}

// --- Main Lesson Widget ---
class UrbanPlannerLesson extends StatefulWidget {
  const UrbanPlannerLesson({Key? key}) : super(key: key);

  @override
  _UrbanPlannerLessonState createState() => _UrbanPlannerLessonState();
}

class _UrbanPlannerLessonState extends State<UrbanPlannerLesson>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  bool _showMidpoint = false;
  bool _showFairpoint = false;
  TestResult? _testLocation;
  late final AudioManager _audioManager;

  // --- Lesson Data ---
  final List<LessonStep> _lessonSteps = [
    LessonStep(
        id: 0,
        type: 'narration',
        narration:
            "You are a senior urban planner for Aikyapur. Your mission is to find the best location for a new hospital. You will need to gather evidence to support your final recommendation."),
    LessonStep(
        id: 1,
        type: 'teaching',
        narration:
            "Let's start with the most obvious option. The **Midpoint Formula** will give us the geographical center, treating both locations equally.",
        formula: "M = ( (x₁ + x₂)/2 , (y₁ + y₂)/2 )"),
    LessonStep(
        id: 2,
        type: 'interaction',
        data: {'interactionType': 'midpoint_input'},
        narration:
            "Calculate the coordinates of this potential location. This will be our first piece of evidence.",
        hint: "The formula uses the x and y values from A(1, 2) and B(9, 8)."),
    LessonStep(
        id: 3,
        type: 'reflection',
        narration:
            "Good. The midpoint represents a perfect **1:1 balance**. Keep this evidence in mind. It's a valid starting point, but we need more data.",
        keyLearning: "Midpoint = Average position, 1:1 balance."),
    LessonStep(
        id: 4,
        type: 'interaction',
        data: {'interactionType': 'choice'},
        narration:
            "Now for a critical piece of social data. The census shows West Aikyapur has **3 times the population** of East Aikyapur. This evidence strongly suggests our location should not be equally balanced.",
        hint:
            "If one area has more people, fairness might mean more than just equal distance."),
    LessonStep(
        id: 5,
        type: 'teaching',
        narration:
            "To account for this imbalance, we'll use the **Section Formula**. This lets us find a 'weighted' average, a point that is mathematically fair to different-sized groups.",
        formula: "P = ( (m₁x₂ + m₂x₁)/(m₁+m₂), ... )"),
    LessonStep(
        id: 6,
        type: 'interaction',
        data: {'interactionType': 'section_formula_input'},
        narration:
            "Let's calculate the coordinates of a 'fair' location using a **3:1 ratio**. This will be our second potential site.",
        hint: "Use m₁=3 for the larger population at B(9, 8)."),
    LessonStep(
        id: 7,
        type: 'reflection',
        narration:
            "Excellent. This new location is mathematically equitable. We now have two potential sites. But there's one final piece of evidence we need...",
        keyLearning: "Section Formula = Weighted, Imbalanced Balance."),
    LessonStep(
        id: 8,
        type: 'narration',
        isMemo: true,
        narration:
            "An URGENT MEMO arrives! A new regulation requires the hospital to be **within 8km of East Aikyapur AND 3km of West Aikyapur**."),
    LessonStep(
        id: 9,
        type: 'interaction',
        data: {'interactionType': 'test_location_choice'},
        narration:
            "This is the final test. Let's run the numbers. Which location complies with the safety regulation?",
        hint: "Select a location to test its compliance."),
    LessonStep(
        id: 10,
        type: 'interaction',
        data: {'interactionType': 'cer'},
        narration:
            "The City Council is waiting. You have all the evidence. Now, construct your final recommendation. Make your claim, present your evidence, and state your reasoning.",
        hint: "Use the evidence you've gathered to build a strong argument."),
    LessonStep(
        id: 11,
        type: 'summary',
        narration:
            "Your recommendation is unanimously approved! Your clear, evidence-based reasoning was undeniable. You didn't just find an answer; you built a powerful case.")
  ];

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager()..init();
  }

  void _handleInteractionComplete({bool isCorrect = true, String? message}) {
    isCorrect
        ? _audioManager.playSound(SoundType.correct)
        : _audioManager.playSound(SoundType.incorrect);
    _showFeedbackDialog(
        isCorrect, message ?? (isCorrect ? "Correct!" : "Try again."));
  }

  void _handleNextStep() {
    if (_step < _lessonSteps.length - 1) {
      setState(() {
        if (_step == 2) _showMidpoint = true;
        if (_step == 6) _showFairpoint = true;
        _step++;
      });
    }
  }

  void _handleTestLocation(String type) {
    _audioManager.playSound(SoundType.click);
    final Point a = Point(1, 2);
    final Point b = Point(9, 8);
    final Point midpoint = Point(5, 5);
    final Point fairpoint = Point(7, 6.5);

    final result = TestResult(
      type: type,
      distA: _calculateDistance(type == 'midpoint' ? midpoint : fairpoint, a),
      distB: _calculateDistance(type == 'midpoint' ? midpoint : fairpoint, b),
    );

    setState(() => _testLocation = result);

    Future.delayed(const Duration(milliseconds: 2500), () {
      _handleInteractionComplete(
          isCorrect: result.passed,
          message:
              "Evidence gathered: The ${result.type == 'midpoint' ? 'Midpoint' : 'Fair Point'} ${result.passed ? 'PASSES' : 'FAILS'} the test.");
    });
  }

  double _calculateDistance(Point p1, Point p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
  }

  void _showFeedbackDialog(bool isCorrect, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FeedbackDialog(
        isCorrect: isCorrect,
        message: message,
        onDismiss: () {
          Navigator.of(context).pop();
          if (isCorrect) {
            _handleNextStep();
          }
          if (_step == 9) {
            // After testing, clear visuals
            setState(() => _testLocation = null);
          }
        },
      ),
    );
  }

  void _restartLesson() {
    _audioManager.playSound(SoundType.success);
    setState(() {
      _step = 0;
      _showMidpoint = false;
      _showFairpoint = false;
      _testLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _lessonSteps[_step];

    if (currentStep.type == 'summary') {
      return SummaryScreen(onRestart: _restartLesson);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text("The Aikyapur Hospital Project",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              ProgressBar(current: _step, total: _lessonSteps.length),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  children: [
                    AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: NarrationBox(
                            key: ValueKey(_step), stepConfig: currentStep)),
                    const SizedBox(height: 16),
                    MapCanvas(
                        step: _step,
                        showMidpoint: _showMidpoint,
                        showFairpoint: _showFairpoint,
                        testLocation: _testLocation),
                  ],
                ),
              ),
              InteractionPane(
                key: ValueKey(_step),
                stepConfig: currentStep,
                onComplete: _handleInteractionComplete,
                onTestLocation: _handleTestLocation,
                onNextStep: () {
                  _audioManager.playSound(SoundType.click);
                  _handleNextStep();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

// All other widgets and classes are defined below to keep the file self-contained.

// --- UI Components ---

class ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const ProgressBar({Key? key, required this.current, required this.total})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double progress = current / (total - 1);
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: MediaQuery.of(context).size.width * progress,
            decoration: BoxDecoration(
              color: Colors.green.shade500,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class NarrationBox extends StatelessWidget {
  final LessonStep stepConfig;
  const NarrationBox({Key? key, required this.stepConfig}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: stepConfig.isMemo ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: stepConfig.isMemo
                  ? Colors.blue.shade200
                  : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (stepConfig.isMemo)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.description, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text("URGENT MEMO",
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold))
            ]),
          _buildFormattedText(stepConfig.narration),
          if (stepConfig.formula != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(stepConfig.formula!,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: Colors.black87))),
            ),
          if (stepConfig.keyLearning != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(stepConfig.keyLearning!,
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700)),
            )
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text) {
    final List<TextSpan> spans = [];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
            fontWeight: i % 2 == 1 ? FontWeight.bold : FontWeight.normal,
            color: i % 2 == 1 ? Colors.green.shade600 : Colors.black87,
            fontSize: 18),
      ));
    }
    return RichText(
        textAlign: TextAlign.center, text: TextSpan(children: spans));
  }
}

class InteractionPane extends StatelessWidget {
  final LessonStep stepConfig;
  final Function({bool isCorrect, String? message}) onComplete;
  final Function(String type) onTestLocation;
  final VoidCallback onNextStep;

  const InteractionPane(
      {Key? key,
      required this.stepConfig,
      required this.onComplete,
      required this.onTestLocation,
      required this.onNextStep})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (stepConfig.type != 'interaction') {
      content = StyledButton(text: "Continue", onPressed: onNextStep);
    } else {
      switch (stepConfig.data['interactionType']) {
        case 'midpoint_input':
        case 'section_formula_input':
          content = _InputForm(
              isMidpoint:
                  stepConfig.data['interactionType'] == 'midpoint_input',
              onCheck: (x, y) {
                bool isCorrect =
                    (stepConfig.data['interactionType'] == 'midpoint_input')
                        ? (x == 5 && y == 5)
                        : (x == 7 && y == 6.5);
                onComplete(
                    isCorrect: isCorrect,
                    message: isCorrect
                        ? "Evidence collected!"
                        : "Not quite. Check your calculations.");
              });
          break;
        case 'choice':
          content = _ChoiceButtons(onComplete: onComplete);
          break;
        case 'test_location_choice':
          content = _TestButtons(onTest: onTestLocation);
          break;
        case 'cer':
          content = _CERComponent(onComplete: onComplete);
          break;
        default:
          content = Container();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: content,
      ),
    );
  }
}

class _InputForm extends StatefulWidget {
  final bool isMidpoint;
  final Function(double?, double?) onCheck;
  const _InputForm({Key? key, required this.isMidpoint, required this.onCheck})
      : super(key: key);

  @override
  __InputFormState createState() => __InputFormState();
}

class __InputFormState extends State<_InputForm> {
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("(",
            style: TextStyle(fontSize: 24, fontFamily: 'monospace')),
        _buildTextField(_xController, "x"),
        const Text(",",
            style: TextStyle(fontSize: 24, fontFamily: 'monospace')),
        _buildTextField(_yController, "y"),
        const Text(")",
            style: TextStyle(fontSize: 24, fontFamily: 'monospace')),
      ]),
      const SizedBox(height: 16),
      StyledButton(
          text: "Check Answer",
          onPressed: () {
            final x = double.tryParse(_xController.text);
            final y = double.tryParse(_yController.text);
            widget.onCheck(x, y);
          })
    ]);
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
            hintText: hint, border: const UnderlineInputBorder()),
      ),
    );
  }
}

class _ChoiceButtons extends StatelessWidget {
  final Function({bool isCorrect, String? message}) onComplete;
  const _ChoiceButtons({Key? key, required this.onComplete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildChoiceButton("Yes, it should be balanced", false),
      const SizedBox(height: 8),
      _buildChoiceButton("No, it shouldn't", true),
    ]);
  }

  Widget _buildChoiceButton(String text, bool isCorrect) {
    return OutlinedButton(
      onPressed: () => onComplete(
          isCorrect: isCorrect,
          message: isCorrect
              ? "Correct. The imbalance is key."
              : "Consider the population difference."),
      child: Text(text),
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48)),
    );
  }
}

class _TestButtons extends StatelessWidget {
  final Function(String) onTest;
  const _TestButtons({Key? key, required this.onTest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StyledButton(
            text: "Test Midpoint", onPressed: () => onTest('midpoint')),
        StyledButton(
            text: "Test Fair Point", onPressed: () => onTest('fairpoint')),
      ],
    );
  }
}

class _CERComponent extends StatefulWidget {
  final Function({bool isCorrect, String? message}) onComplete;
  const _CERComponent({Key? key, required this.onComplete}) : super(key: key);

  @override
  __CERComponentState createState() => __CERComponentState();
}

class __CERComponentState extends State<_CERComponent> {
  String? _claim;
  final Set<String> _evidence = {};
  final List<TextEditingController> _reasoningControllers =
      List.generate(4, (_) => TextEditingController());

  final List<String> _evidenceOptions = const [
    "The Midpoint failed the safety test",
    "The Fair Point is closer to the larger population",
    "The Fair Point passed the safety test",
    "The Midpoint is the geographical center"
  ];

  void _checkCER() {
    final correctEvidence = {
      "The Midpoint failed the safety test",
      "The Fair Point is closer to the larger population",
      "The Fair Point passed the safety test"
    };
    final correctReasoning = [
      "geographical",
      "fails the safety regulation",
      "access",
      "complies"
    ];
    final isClaimCorrect = _claim == 'fairpoint';
    final isEvidenceCorrect = _evidence.length == correctEvidence.length &&
        _evidence.every((e) => correctEvidence.contains(e));
    final isReasoningCorrect = _reasoningControllers.asMap().entries.every(
        (entry) =>
            entry.value.text.trim().toLowerCase() ==
            correctReasoning[entry.key]);

    widget.onComplete(
        isCorrect: isClaimCorrect && isEvidenceCorrect && isReasoningCorrect,
        message: isClaimCorrect && isEvidenceCorrect && isReasoningCorrect
            ? "A perfect argument!"
            : "Your reasoning has a flaw. Review the evidence.");
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionTitle("CLAIM: My Recommendation"),
          DropdownButtonFormField<String>(
            value: _claim,
            items: const [
              DropdownMenuItem(
                  value: 'midpoint', child: Text("Build at Midpoint M(5, 5)")),
              DropdownMenuItem(
                  value: 'fairpoint',
                  child: Text("Build at Fair Point P(7, 6.5)"))
            ],
            onChanged: (val) => setState(() => _claim = val),
            decoration: const InputDecoration(
                border: OutlineInputBorder(), hintText: "Select a location..."),
          ),
          const SizedBox(height: 12),
          _buildSectionTitle("EVIDENCE: Supporting Facts"),
          ..._evidenceOptions.map(
            (opt) => CheckboxListTile(
                title: Text(opt, style: const TextStyle(fontSize: 14)),
                value: _evidence.contains(opt),
                onChanged: (val) => setState(
                    () => val! ? _evidence.add(opt) : _evidence.remove(opt))),
          ),
          const SizedBox(height: 12),
          _buildSectionTitle("REASONING: The Argument"),
          RichText(
              text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                const TextSpan(text: "While the Midpoint is the "),
                WidgetSpan(
                    child: _buildReasoningInput(_reasoningControllers[0])),
                const TextSpan(text: " center, it is unsuitable because it "),
                WidgetSpan(
                    child: _buildReasoningInput(_reasoningControllers[1])),
                const TextSpan(
                    text:
                        ". The Fair Point is the only viable option because it provides more equitable "),
                WidgetSpan(
                    child: _buildReasoningInput(_reasoningControllers[2])),
                const TextSpan(
                    text:
                        " to the larger population and is the only location that "),
                WidgetSpan(
                    child: _buildReasoningInput(_reasoningControllers[3])),
                const TextSpan(text: " with the mandatory safety distances."),
              ])),
          const SizedBox(height: 16),
          Center(
              child: StyledButton(
                  text: "Submit Recommendation", onPressed: _checkCER)),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  Widget _buildReasoningInput(TextEditingController controller) => SizedBox(
      width: 100,
      child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
              isDense: true, border: UnderlineInputBorder())));
}

class StyledButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const StyledButton({Key? key, required this.text, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade500,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

class FeedbackDialog extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final VoidCallback onDismiss;
  const FeedbackDialog(
      {Key? key,
      required this.isCorrect,
      required this.message,
      required this.onDismiss})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            TextButton(onPressed: onDismiss, child: const Text("OK")),
          ],
        ),
      ),
    );
  }
}

class SummaryScreen extends StatelessWidget {
  final VoidCallback onRestart;
  const SummaryScreen({Key? key, required this.onRestart}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Recommendation Approved!",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 10)
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Your Final Report",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildSummaryItem("Claim:",
                        "Argued successfully for the Fair Point location."),
                    _buildSummaryItem("Evidence:",
                        "Used population data and safety test results to prove your case."),
                    _buildSummaryItem("Reasoning:",
                        "Logically explained why the Fair Point was the only choice that was both equitable and safe."),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              StyledButton(text: "Plan Another City", onPressed: onRestart)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check, color: Colors.green, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: RichText(
                text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    children: [
              TextSpan(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: " $body"),
            ]))),
      ]),
    );
  }
}

class MapCanvas extends StatefulWidget {
  final int step;
  final bool showMidpoint;
  final bool showFairpoint;
  final TestResult? testLocation;
  const MapCanvas(
      {Key? key,
      required this.step,
      required this.showMidpoint,
      required this.showFairpoint,
      this.testLocation})
      : super(key: key);

  @override
  _MapCanvasState createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  void didUpdateWidget(covariant MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.testLocation != oldWidget.testLocation &&
        widget.testLocation != null) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: -2,
                  blurRadius: 5,
                  offset: const Offset(0, 5))
            ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: MapPainter(
              step: widget.step,
              showMidpoint: widget.showMidpoint,
              showFairpoint: widget.showFairpoint,
              testResult: widget.testLocation,
              animation: _controller,
            ),
            child: Stack(children: [
              if (widget.testLocation != null)
                Center(
                    child: Stamp(
                        passed: widget.testLocation!.passed,
                        animation: _controller)),
            ]),
          ),
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final int step;
  final bool showMidpoint;
  final bool showFairpoint;
  final TestResult? testResult;
  final Animation<double> animation;

  MapPainter(
      {required this.step,
      required this.showMidpoint,
      required this.showFairpoint,
      this.testResult,
      required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.green.shade200.withOpacity(0.5)
      ..strokeWidth = 1;
    for (int i = 1; i < 10; i++) {
      canvas.drawLine(Offset(size.width * i / 10, 0),
          Offset(size.width * i / 10, size.height), paintGrid);
      canvas.drawLine(Offset(0, size.height * i / 10),
          Offset(size.width, size.height * i / 10), paintGrid);
    }

    if (step >= 1) {
      _drawPoint(canvas, size, Point(1, 2), "A(1,2)", Colors.blue);
      _drawPoint(canvas, size, Point(9, 8), "B(9,8)", Colors.purple);
    }

    if (showMidpoint) _drawHospital(canvas, size, Point(5, 5), Colors.red);
    if (showFairpoint)
      _drawHospital(canvas, size, Point(7, 6.5), Colors.orange);

    if (testResult != null) {
      final circleAnimation =
          CurvedAnimation(parent: animation, curve: Curves.easeOut);
      _drawTestCircle(canvas, size, Point(1, 2), 8, testResult!.distA <= 8,
          circleAnimation.value);
      _drawTestCircle(canvas, size, Point(9, 8), 3, testResult!.distB <= 3,
          circleAnimation.value);
    }
  }

  void _drawPoint(
      Canvas canvas, Size size, Point p, String label, Color color) {
    final offset = Offset(size.width * p.x / 10, size.height * p.y / 10);
    canvas.drawCircle(offset, 12, Paint()..color = color);
    TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, offset + const Offset(-15, 15));
  }

  void _drawHospital(Canvas canvas, Size size, Point p, Color color) {
    final offset = Offset(size.width * p.x / 10, size.height * p.y / 10);
    canvas.drawCircle(offset, 16, Paint()..color = color);
    final icon = Icons.local_hospital;
    TextPainter(
        text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: icon.fontFamily)),
        textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, offset - const Offset(12, 12));
  }

  void _drawTestCircle(Canvas canvas, Size size, Point p, double radius,
      bool passed, double animationValue) {
    final center = Offset(size.width * p.x / 10, size.height * p.y / 10);
    final scaledRadius = size.width * radius / 10;
    final paint = Paint()
      ..color = (passed ? Colors.green : Colors.red).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, scaledRadius * animationValue, paint);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => true;
}

class Stamp extends StatelessWidget {
  final bool passed;
  final Animation<double> animation;
  const Stamp({Key? key, required this.passed, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut));
    return ScaleTransition(
      scale: scaleAnimation,
      child: Transform.rotate(
        angle: -0.2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border:
                Border.all(color: passed ? Colors.green : Colors.red, width: 8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(passed ? "PASSED" : "FAILED",
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.green : Colors.red)),
        ),
      ),
    );
  }
}

// --- Helper Classes & Audio Manager ---

class Point {
  final double x, y;
  Point(this.x, this.y);
}

class TestResult {
  final String type;
  final double distA, distB;
  bool get passed => distA <= 8 && distB <= 3;
  TestResult({required this.type, required this.distA, required this.distB});
}

enum SoundType { click, correct, incorrect, success }

class AudioManager {
  final AudioPlayer _player = AudioPlayer();
  Map<SoundType, String> _soundPaths = {};

  Future<void> init() async {
    try {
      _soundPaths[SoundType.click] = "sounds/click.wav";
      _soundPaths[SoundType.correct] = "sounds/correct.wav";
      _soundPaths[SoundType.incorrect] = "sounds/incorrect.wav";
      _soundPaths[SoundType.success] = "sounds/success.wav";
    } catch (e) {
      // Sounds will not play if assets are not available.
      debugPrint(
          "Error loading sounds: $e. You may need to create and add the .wav files to your assets folder.");
    }
  }

  void playSound(SoundType type) {
    if (_soundPaths.containsKey(type)) {
      _player.play(AssetSource(_soundPaths[type]!));
    }
  }
}

// Note for user: To make sounds work, create an `assets/sounds` directory in your Flutter project root,
// add short .wav files named `click.wav`, `correct.wav`, `incorrect.wav`, `success.wav`,
// and add the following to your `pubspec.yaml`:
// flutter:
//   assets:
//     - assets/sounds/
