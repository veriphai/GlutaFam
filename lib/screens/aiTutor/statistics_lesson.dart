import 'package:flutter/material.dart';

// --- Sound Service ---
class SoundService {
  Future<void> _playSound(String sound) async {
    // In a real app, you'd have actual sound files.
    // Here we'll just pretend to play them.
    // Example: await AudioPlayer().play(AssetSource('sounds/$sound.mp3'));
    debugPrint('Playing sound: $sound');
  }

  void playCorrect() => _playSound('correct');
  void playIncorrect() => _playSound('incorrect');
  void playTransition() => _playSound('transition');
}

// --- Data ---

const List<int> cricketerScores = [
  15,
  88,
  2,
  43,
  0,
  102,
  19,
  56,
  7,
  65,
  12,
  1,
  94,
  33,
  5,
  48,
  22,
  71,
  8,
  3,
  29,
  61,
  14,
  82,
  38,
  4,
  17,
  55,
  99,
  6,
  25,
  41,
  11,
  78,
  9,
  30,
  51,
  68,
  18,
  0,
  85,
  23,
  37,
  49,
  60,
  7,
  91,
  16,
  28,
  44,
  58,
  2,
  72,
  13,
  35,
  81,
  97,
  21,
  40,
  66,
  10,
  5,
  26,
  50,
  75,
  89,
  4,
  32,
  1,
  63,
  20,
  47,
  53,
  7,
  9,
  34,
  45,
  69,
  83,
  96,
  11,
  24,
  39,
  59,
  73,
  80,
  6,
  19,
  42,
  52,
  77,
  93,
  3,
  27,
  31
];

class ClassInterval {
  final String label;
  final int lower;
  final int upper;

  const ClassInterval(
      {required this.label, required this.lower, required this.upper});
}

const List<ClassInterval> classIntervals = [
  ClassInterval(label: '0-20', lower: 0, upper: 20),
  ClassInterval(label: '21-40', lower: 21, upper: 40),
  ClassInterval(label: '41-60', lower: 41, upper: 60),
  ClassInterval(label: '61-80', lower: 61, upper: 80),
  ClassInterval(label: '81-100+', lower: 81, upper: 110),
];

class AnalysisData {
  final String label;
  final int lower;
  final int upper;
  final int frequency;
  final double classMark;
  final double fiXi;

  AnalysisData({
    required this.label,
    required this.lower,
    required this.upper,
    required this.frequency,
    required this.classMark,
    required this.fiXi,
  });
}

final List<AnalysisData> analysisData = classIntervals.map((interval) {
  final frequency = cricketerScores
      .where((score) => score >= interval.lower && score <= interval.upper)
      .length;
  final classMark = (interval.lower + interval.upper) / 2;
  return AnalysisData(
    label: interval.label,
    lower: interval.lower,
    upper: interval.upper,
    frequency: frequency,
    classMark: classMark,
    fiXi: frequency * classMark,
  );
}).toList();

final double totalApproxRuns =
    analysisData.fold(0, (sum, row) => sum + row.fiXi);
final int totalInnings =
    analysisData.fold(0, (sum, row) => sum + row.frequency);
final double estimatedAverage = totalApproxRuns / totalInnings;

// --- Helper Components & Data ---

class StyledText extends StatelessWidget {
  final String text;

  const StyledText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    // This is a simplified version. For more complex styling,
    // you might want to use a package like flutter_markdown.
    return Text.rich(
      TextSpan(
        style:
            const TextStyle(fontSize: 18, color: Colors.black87, height: 1.5),
        children: _buildTextSpans(),
      ),
    );
  }

  List<TextSpan> _buildTextSpans() {
    final List<TextSpan> spans = [];
    final parts = text.split(RegExp(r'(\*.*?\*)'));
    for (var part in parts) {
      if (part.startsWith('*') && part.endsWith('*')) {
        spans.add(TextSpan(
          text: part.substring(1, part.length - 1),
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ));
      } else {
        spans.add(TextSpan(text: part));
      }
    }
    return spans;
  }
}

class ProgressBar extends StatelessWidget {
  final double progress;

  const ProgressBar({required this.progress, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.close, color: Colors.grey, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.flash_on, color: Colors.yellow, size: 24),
        ],
      ),
    );
  }
}

class MainButton extends StatelessWidget {
  final VoidCallback? onClick;
  final Widget child;
  final bool disabled;
  final bool isCorrect;

  const MainButton({
    required this.onClick,
    required this.child,
    this.disabled = false,
    this.isCorrect = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: disabled ? null : onClick,
      style: ElevatedButton.styleFrom(
        backgroundColor: disabled
            ? Colors.grey[300]
            : (isCorrect ? Colors.green : Colors.black),
        foregroundColor: disabled ? Colors.grey[500] : Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: child,
    );
  }
}

// --- Screen Components ---

class TeachingScreen extends StatelessWidget {
  final VoidCallback onNext;
  final String title;
  final Widget child;
  final String? imageSrc;
  final String? altText;

  const TeachingScreen({
    required this.onNext,
    required this.title,
    required this.child,
    this.imageSrc,
    this.altText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageSrc != null)
            Image.network(imageSrc!, height: 150, semanticLabel: altText)
          else
            const Icon(Icons.book, size: 100, color: Colors.green),
          const SizedBox(height: 24),
          Text(title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 24),
          MainButton(
            onClick: onNext,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class IntroScreen extends StatelessWidget {
  final VoidCallback onNext;

  const IntroScreen({required this.onNext, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Signing the Next Superstar',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Image.network(
            'https://placehold.co/300x200/34D399/FFFFFF?text=T20+Auction&font=inter',
            height: 200,
          ),
          const SizedBox(height: 24),
          const StyledText(
              "You're a data analyst. The coach needs a recommendation, and he needs it backed by *solid data*. Let's build our case."),
          const SizedBox(height: 24),
          MainButton(
            onClick: onNext,
            child: const Text("Let's Get Started"),
          ),
        ],
      ),
    );
  }
}

class RawDataScreen extends StatefulWidget {
  final VoidCallback onNext;
  final SoundService soundService;
  // final VoidCallback playIncorrect; // Sounds to be added later
  // final VoidCallback playCorrect;

  const RawDataScreen(
      {required this.onNext, required this.soundService, super.key});

  @override
  State<RawDataScreen> createState() => _RawDataScreenState();
}

class _RawDataScreenState extends State<RawDataScreen> {
  String? _selection;
  bool _showFeedback = false;

  void _checkAnswer() {
    final isCorrect = _selection == 'hard';
    if (isCorrect) {
      widget.soundService.playCorrect();
      widget.onNext();
    } else {
      widget.soundService.playIncorrect();
      setState(() {
        _showFeedback = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text("Rohan's Last 100 Scores",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                childAspectRatio: 1.5,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: cricketerScores.length,
              itemBuilder: (context, index) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cricketerScores[index].toString(),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
              "Let's start with an initial hypothesis. What's your gut feeling?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          const Text("Looking at this messy data, what can we say for sure?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          _buildOption("He's a great player.", 'great'),
          _buildOption("He's a bad player.", 'bad'),
          _buildOption("It's hard to tell for sure.", 'hard'),
          if (_showFeedback && _selection != 'hard')
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: "That's a fair gut feeling, but...\n",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text:
                          "A professional analyst can't rely on feelings. We need hard evidence. Let's dig deeper."),
                ]),
                style: TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 24),
          MainButton(
            onClick: _checkAnswer,
            disabled: _selection == null,
            child: const Text('This is my hypothesis'),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String text, String value) {
    final isSelected = _selection == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selection = value;
        _showFeedback = false;
      }),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      ),
    );
  }
}

class GroupingScreen extends StatefulWidget {
  final VoidCallback onNext;
  final SoundService soundService;

  const GroupingScreen(
      {required this.onNext, required this.soundService, super.key});

  @override
  State<GroupingScreen> createState() => _GroupingScreenState();
}

class _GroupingScreenState extends State<GroupingScreen> {
  int? _selectedScore;
  Map<int, String> _placedScores = {};
  String _feedback = '';
  final List<int> _scoresToPlace = [15, 88, 43];

  void _handleSelectScore(int score) {
    if (_placedScores.containsKey(score)) return;
    setState(() {
      _selectedScore = score;
      _feedback = '';
    });
  }

  void _handlePlaceScore(ClassInterval interval) {
    if (_selectedScore == null) return;

    if (_selectedScore! >= interval.lower &&
        _selectedScore! <= interval.upper) {
      setState(() {
        _placedScores[_selectedScore!] = interval.label;
        _selectedScore = null;
        _feedback = 'Correct!';
      });
      widget.soundService.playCorrect();

      if (_placedScores.length == _scoresToPlace.length) {
        setState(() {
          _feedback = 'Great job! Sorting the rest...';
        });
        Future.delayed(const Duration(seconds: 2), widget.onNext);
      }
    } else {
      setState(() {
        _feedback = 'Oops! Try a different bin.';
      });
      widget.soundService.playIncorrect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text("Gathering Evidence: Grouping",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            "Let's bring order to this chaos by grouping the data into 'bins' called *Class Intervals*.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                const Text("Drag these scores to the correct bin:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _scoresToPlace
                      .map((score) => ElevatedButton(
                            onPressed: () => _handleSelectScore(score),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _placedScores.containsKey(score)
                                  ? Colors.grey
                                  : (_selectedScore == score
                                      ? Colors.green
                                      : Colors.white),
                              foregroundColor: _placedScores.containsKey(score)
                                  ? Colors.white
                                  : (_selectedScore == score
                                      ? Colors.white
                                      : Colors.black),
                            ),
                            child: Text('$score',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...classIntervals.map((interval) {
            final scoresInBin = _placedScores.entries
                .where((e) => e.value == interval.label)
                .map((e) => e.key);
            return GestureDetector(
              onTap: () => _handlePlaceScore(interval),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey[400]!,
                      style: BorderStyle.solid,
                      width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${interval.label} runs',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ...scoresInBin.map((score) => Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Chip(
                            label: Text('$score'),
                            backgroundColor: Colors.green[100],
                          ),
                        )),
                  ],
                ),
              ),
            );
          }),
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                _feedback,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _feedback.startsWith('Correct') ||
                          _feedback.startsWith('Great')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FrequencyTableScreen extends StatefulWidget {
  final VoidCallback onNext;
  final SoundService soundService;

  const FrequencyTableScreen(
      {required this.onNext, required this.soundService, super.key});

  @override
  State<FrequencyTableScreen> createState() => _FrequencyTableScreenState();
}

class _FrequencyTableScreenState extends State<FrequencyTableScreen> {
  String? _selection;

  void _checkAnswer() {
    if (_selection == 'risk') {
      widget.soundService.playCorrect();
      widget.onNext();
    } else {
      widget.soundService.playIncorrect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = _selection == 'risk';
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text("Evidence Piece #1: The Pattern",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
              "Now we can see a clear pattern. This is a *Frequency Distribution Table*.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
              columns: const [
                DataColumn(
                    label: Text('Runs Scored (Class)',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Innings (Frequency)',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: analysisData
                  .map((row) => DataRow(cells: [
                        DataCell(Text(row.label)),
                        DataCell(Text(row.frequency.toString(),
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 16))),
                      ]))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text("What is the key insight from this evidence?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          _buildOption("He is a slow but steady player.", 'steady'),
          _buildOption(
              "He often gets out for a low score, but can also score big.",
              'risk'),
          if (isCorrect)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                  "Correct! You've identified the 'high-risk, high-reward' pattern. This is a crucial piece of evidence.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 24),
          MainButton(
            onClick: _checkAnswer,
            disabled: _selection == null,
            isCorrect: isCorrect,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String text, String value) {
    final isSelected = _selection == value;
    return GestureDetector(
      onTap: () => setState(() => _selection = value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      ),
    );
  }
}

class ClassMarkIntroScreen extends StatelessWidget {
  final VoidCallback onNext;

  const ClassMarkIntroScreen({required this.onNext, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Finding a Hard Number",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Image.network(
            'https://placehold.co/150x150/FBBF24/FFFFFF?text=?&font=inter',
            height: 150,
          ),
          const SizedBox(height: 24),
          const Text(
            "\"Good start,\" says the coach. \"But 'high-risk, high-reward' is an observation. To convince me, I need a hard number. Let's find more *evidence*.\"",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 24),
          MainButton(
            onClick: onNext,
            child: const Text("Find the key number"),
          ),
        ],
      ),
    );
  }
}

class ClassMarkCalculationScreen extends StatefulWidget {
  final VoidCallback onNext;
  final SoundService soundService;
  const ClassMarkCalculationScreen(
      {required this.onNext, required this.soundService, super.key});

  @override
  State<ClassMarkCalculationScreen> createState() =>
      _ClassMarkCalculationScreenState();
}

class _ClassMarkCalculationScreenState
    extends State<ClassMarkCalculationScreen> {
  final _controller = TextEditingController();
  bool? _isCorrect;

  void _checkAnswer() {
    final answer = double.tryParse(_controller.text);
    if (answer == 50.5) {
      widget.soundService.playCorrect();
      setState(() => _isCorrect = true);
      Future.delayed(const Duration(milliseconds: 1500), widget.onNext);
    } else {
      widget.soundService.playIncorrect();
      setState(() => _isCorrect = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text("Evidence Piece #2: The Class Mark",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
              "The fairest assumption is to use the value right in the *middle*. This is the *Class Mark*.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text("Class Mark =",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("(Lower Limit + Upper Limit) / 2",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 20)),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                const Text("Calculate the Class Mark for the '41-60' interval.",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Text("(41 + 60) / 2 = ?",
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Type your answer",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                _isCorrect == false ? Colors.red : Colors.green,
                            width: 2)),
                  ),
                  onChanged: (_) => setState(() => _isCorrect = null),
                ),
              ],
            ),
          ),
          if (_isCorrect == false)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8)),
              child: const Text(
                  "Not quite. Let's review.\nFor the '41-60' interval, that's (41 + 60) / 2 = 101 / 2 = 50.5.\n\nTry entering 50.5!",
                  style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 24),
          MainButton(
            onClick: _checkAnswer,
            disabled: _controller.text.isEmpty,
            isCorrect: _isCorrect == true,
            child: _isCorrect == true
                ? const Icon(Icons.check)
                : const Text('Check'),
          )
        ],
      ),
    );
  }
}

class CompleteTableScreen extends StatefulWidget {
  final VoidCallback onNext;
  final SoundService soundService;
  const CompleteTableScreen(
      {required this.onNext, required this.soundService, super.key});

  @override
  State<CompleteTableScreen> createState() => _CompleteTableScreenState();
}

class _CompleteTableScreenState extends State<CompleteTableScreen> {
  late List<TextEditingController> _controllers;
  bool? _allCorrect;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(analysisData.length, (_) => TextEditingController());
  }

  void _checkAnswers() {
    bool correct = true;
    for (int i = 0; i < analysisData.length; i++) {
      if (double.tryParse(_controllers[i].text) != analysisData[i].classMark) {
        correct = false;
        break;
      }
    }
    setState(() => _allCorrect = correct);
    if (correct) {
      widget.soundService.playCorrect();
      Future.delayed(const Duration(milliseconds: 1500), widget.onNext);
    } else {
      widget.soundService.playIncorrect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text("Gathering More Evidence",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
              "Excellent. Now complete the table by finding the Class Mark for every interval.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Class')),
              DataColumn(label: Text('Freq (fᵢ)')),
              DataColumn(label: Text('Class Mark (xᵢ)')),
            ],
            rows: List.generate(analysisData.length, (index) {
              final row = analysisData[index];
              return DataRow(cells: [
                DataCell(Text(row.label)),
                DataCell(Text(row.frequency.toString())),
                DataCell(TextField(
                    controller: _controllers[index],
                    keyboardType: TextInputType.number)),
              ]);
            }),
          ),
          if (_allCorrect == false)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Not quite! Double-check your calculations.",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 24),
          MainButton(
            onClick: _checkAnswers,
            isCorrect: _allCorrect == true,
            child: _allCorrect == true
                ? const Icon(Icons.check)
                : const Text('Check My Work'),
          )
        ],
      ),
    );
  }
}

class PowerOfClassMarkScreen extends StatefulWidget {
  final VoidCallback onNext;
  final SoundService soundService;
  const PowerOfClassMarkScreen(
      {required this.onNext, required this.soundService, super.key});

  @override
  State<PowerOfClassMarkScreen> createState() => _PowerOfClassMarkScreenState();
}

class _PowerOfClassMarkScreenState extends State<PowerOfClassMarkScreen> {
  final _controller = TextEditingController();
  bool? _isCorrect;
  bool _showFullColumn = false;
  final firstRow = analysisData[0];

  void _checkAnswer() {
    if (double.tryParse(_controller.text) == firstRow.fiXi) {
      widget.soundService.playCorrect();
      setState(() {
        _isCorrect = true;
        _showFullColumn = true;
      });
    } else {
      widget.soundService.playIncorrect();
      setState(() => _isCorrect = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text("Crucial Evidence: The Average",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
              "Now we can estimate his total runs for each group by multiplying Frequency (fᵢ) by the Class Mark (xᵢ).",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('fᵢ')),
              DataColumn(label: Text('xᵢ')),
              DataColumn(label: Text('fᵢ xᵢ')),
            ],
            rows: [
              ...List.generate(analysisData.length, (index) {
                final row = analysisData[index];
                return DataRow(
                  cells: [
                    DataCell(Text(row.frequency.toString())),
                    DataCell(Text(row.classMark.toString())),
                    DataCell(index == 0
                        ? TextField(
                            controller: _controller,
                            keyboardType: TextInputType.number)
                        : Text(_showFullColumn ? row.fiXi.toString() : '?')),
                  ],
                  color: MaterialStateProperty.all(index > 0 && !_showFullColumn
                      ? Colors.grey[200]
                      : Colors.transparent),
                );
              }),
              if (_showFullColumn)
                DataRow(
                  cells: [
                    const DataCell(Text('Total (Σfᵢxᵢ)',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataCell(Text('')),
                    DataCell(Text(totalApproxRuns.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  color: MaterialStateProperty.all(Colors.grey[300]),
                ),
            ],
          ),
          if (_isCorrect == false)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  "Not quite. Remember: ${firstRow.frequency} × ${firstRow.classMark} = ${firstRow.fiXi}.",
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 24),
          MainButton(
            onClick: _showFullColumn ? widget.onNext : _checkAnswer,
            isCorrect: _isCorrect == true,
            child: Text(_showFullColumn ? 'Calculate Average' : 'Check'),
          ),
        ],
      ),
    );
  }
}

class BuildReportScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) setReportData;
  final VoidCallback onNext;
  final SoundService soundService;
  const BuildReportScreen(
      {required this.onNext,
      required this.setReportData,
      required this.soundService,
      super.key});

  @override
  State<BuildReportScreen> createState() => _BuildReportScreenState();
}

class _BuildReportScreenState extends State<BuildReportScreen> {
  String? _claim;
  List<String> _evidence = [];
  List<String> _reasoning = [];
  String _feedback = "";
  final _correctEvidence = ['avg', 'risk', 'reward'];
  final _allReasoning = [
    "his high average of 35.4 shows his overall value.",
    "even though he is risky,",
    "his ability to win matches with big scores is what our team needs."
  ];

  void _toggleEvidence(String id) {
    setState(() {
      if (_evidence.contains(id)) {
        _evidence.remove(id);
      } else {
        _evidence.add(id);
      }
    });
  }

  void _submitReport() {
    if (_claim == null) {
      widget.soundService.playIncorrect();
      setState(() => _feedback = "You must make a claim!");
      return;
    }
    if (_evidence.length != 3 ||
        !_correctEvidence.every((e) => _evidence.contains(e))) {
      widget.soundService.playIncorrect();
      setState(() => _feedback =
          "Your evidence is incomplete or incorrect. Select the 3 strongest points.");
      return;
    }
    if (_reasoning.length != 3) {
      widget.soundService.playIncorrect();
      setState(() =>
          _feedback = "Complete your reasoning to make a strong argument.");
      return;
    }
    widget.soundService.playCorrect();
    widget.setReportData(
        {'claim': _claim, 'evidence': _evidence, 'reasoning': _reasoning});
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text("Your Analyst Report",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("Present your final recommendation to the coach.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),

          // Claim Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("1. Your Claim",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _claim = 'sign'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _claim == 'sign'
                                    ? Colors.green
                                    : Colors.grey[200],
                                foregroundColor: _claim == 'sign'
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child: const Text('Sign Rohan'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  setState(() => _claim = 'dont_sign'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _claim == 'dont_sign'
                                    ? Colors.red
                                    : Colors.grey[200],
                                foregroundColor: _claim == 'dont_sign'
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              child: const Text("Don't Sign"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Evidence Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("2. Your Evidence (Select 3)",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(height: 8),
                      _buildEvidenceOption(
                          "His average is 35.4, higher than the alternative.",
                          'avg'),
                      _buildEvidenceOption(
                          "He gets out for low scores 40% of the time.",
                          'risk'),
                      _buildEvidenceOption(
                          "He scores 81+ runs 10% of the time.", 'reward'),
                      _buildEvidenceOption(
                          "His highest score was 102.", 'highest'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Reasoning Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("3. Your Reasoning",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(height: 4),
                      const Text("Drag the phrases to build your argument.",
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "\"My recommendation is to sign him because ${_reasoning.join(" ")}\"",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _allReasoning
                            .where((phrase) => !_reasoning.contains(phrase))
                            .map((phrase) => GestureDetector(
                                  onTap: () => _handleDrop(phrase),
                                  child: Chip(
                                    label: Text(phrase,
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.blue[100],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          if (_feedback.isNotEmpty)
            Text(_feedback,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          MainButton(onClick: _submitReport, child: const Text("Submit Report"))
        ],
      ),
    );
  }

  Widget _buildEvidenceOption(String text, String id) {
    final isSelected = _evidence.contains(id);
    return GestureDetector(
      onTap: () => _toggleEvidence(id),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.transparent,
          border:
              Border.all(color: isSelected ? Colors.green : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  void _handleDrop(String phrase) {
    if (!_reasoning.contains(phrase)) {
      setState(() {
        _reasoning.add(phrase);
      });
    }
  }
}

class MissionAccomplishedScreen extends StatelessWidget {
  final VoidCallback onRestart;
  final Map<String, dynamic> reportData;
  const MissionAccomplishedScreen(
      {required this.onRestart, required this.reportData, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Icon(Icons.assessment, size: 100, color: Colors.green),
          const SizedBox(height: 24),
          const Text("A Bulletproof Argument!",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          const SizedBox(height: 16),
          const StyledText(
              "You didn't just give an opinion. You made a *Claim*, backed it with statistical *Evidence*, and explained your *Reasoning*. The coach is convinced!"),
          const SizedBox(height: 16),

          // Final Report section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Your Final Report",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: "CLAIM: ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      TextSpan(text: "We should sign Rohan Sharma."),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: "EVIDENCE:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• Estimated average is 35.4."),
                      Text("• High risk (out below 20 runs, 40% of the time)."),
                      Text("• High reward (scores 81+ runs, 10% of the time)."),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                          text: "REASONING: ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      TextSpan(
                          text:
                              "\"...${(reportData['reasoning'] as List<String>?)?.join(" ") ?? "his high average shows value, even though risky, his big scores are what we need."}\""),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          MainButton(
              onClick: onRestart, child: const Text("Start a New Analysis"))
        ],
      ),
    );
  }
}

// --- Main App Component ---

class StatisticsLessonScreen extends StatefulWidget {
  const StatisticsLessonScreen({super.key});

  @override
  State<StatisticsLessonScreen> createState() => _StatisticsLessonScreenState();
}

class _StatisticsLessonScreenState extends State<StatisticsLessonScreen> {
  int _step = 0;
  Map<String, dynamic> _reportData = {'reasoning': []};
  final SoundService _soundService = SoundService();

  void _handleNext() {
    _soundService.playTransition();
    setState(() {
      _step++;
    });
  }

  void _handleRestart() {
    _soundService.playTransition();
    setState(() {
      _step = 0;
      _reportData = {'reasoning': []};
    });
  }

  void _setReportData(Map<String, dynamic> data) {
    setState(() {
      _reportData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      IntroScreen(key: ValueKey(0), onNext: _handleNext),
      RawDataScreen(
          key: ValueKey(1), onNext: _handleNext, soundService: _soundService),
      TeachingScreen(
        key: ValueKey(2),
        onNext: _handleNext,
        title: "The 'Why' of Grouping",
        imageSrc:
            "https://placehold.co/300x150/A7F3D0/1F2937?text=Chaos+%E2%86%92+Order&font=inter",
        altText: "Chaos to Order",
        child: Column(
          children: [
            StyledText(
                "Our brains aren't built to find patterns in a giant wall of numbers. So, what do we do? We group them!"),
            SizedBox(height: 16),
            StyledText(
                "This is the first secret of any data analyst: *turn chaos into clear, manageable groups.* This process is called *condensing the data*."),
          ],
        ),
      ),
      GroupingScreen(
          key: ValueKey(3), onNext: _handleNext, soundService: _soundService),
      FrequencyTableScreen(
          key: ValueKey(4), onNext: _handleNext, soundService: _soundService),
      TeachingScreen(
        key: ValueKey(5),
        onNext: _handleNext,
        title: "What We've Built",
        imageSrc:
            "https://placehold.co/300x150/BEF264/1F2937?text=Frequency+Table&font=inter",
        altText: "Frequency Table",
        child: Column(
          children: [
            StyledText(
                "Excellent! You've just created a *Frequency Distribution Table*, a fundamental tool in statistics. Let's recap:"),
            SizedBox(height: 16),
            StyledText(
                "1. *Class Interval:* The 'bin' you put scores into (e.g., '0-20')."),
            StyledText(
                "2. *Frequency:* How *many* scores fall into that bin (e.g., 40)."),
            SizedBox(height: 16),
            StyledText(
                "*Mental Model:* Think of it like sorting laundry. Each basket is a *Class Interval*, and the number of clothes inside is the *Frequency*."),
          ],
        ),
      ),
      ClassMarkIntroScreen(key: ValueKey(6), onNext: _handleNext),
      TeachingScreen(
        key: ValueKey(7),
        onNext: _handleNext,
        title: "Why the Middle?",
        imageSrc:
            "https://placehold.co/300x150/FDE68A/1F2937?text=41+%E2%86%90+50.5+%E2%86%92+60&font=inter",
        altText: "Midpoint",
        child: Column(
          children: [
            StyledText(
                "When we group data, we lose the original scores. For the '41-60' group, the score could have been 41, 55, or 60."),
            SizedBox(height: 16),
            StyledText(
                "By choosing the *midpoint* (the Class Mark), we make the fairest possible assumption: that the scores are evenly spread out. It is the most *balanced and representative* value for the whole group."),
          ],
        ),
      ),
      ClassMarkCalculationScreen(
          key: ValueKey(8), onNext: _handleNext, soundService: _soundService),
      CompleteTableScreen(
          key: ValueKey(9), onNext: _handleNext, soundService: _soundService),
      PowerOfClassMarkScreen(
          key: ValueKey(10), onNext: _handleNext, soundService: _soundService),
      TeachingScreen(
        key: ValueKey(11),
        onNext: _handleNext,
        title: "The Big Picture",
        imageSrc:
            "https://placehold.co/300x150/A5B4FC/1F2937?text=Data+%E2%86%92+Decision&font=inter",
        altText: "Data to Decision",
        child: Column(
          children: [
            StyledText("Let's pause and see the process you just mastered:"),
            SizedBox(height: 16),
            StyledText("1. You tamed chaos by *Grouping* it."),
            StyledText(
                "2. You found a representative for each group (the *Class Mark*)."),
            StyledText(
                "3. You used these to estimate the player's true average and make a decision."),
            SizedBox(height: 16),
            StyledText(
                "This is the core of how analysts handle huge amounts of data to find *meaningful answers*."),
          ],
        ),
      ),
      BuildReportScreen(
          key: ValueKey(12),
          onNext: _handleNext,
          setReportData: _setReportData,
          soundService: _soundService),
      MissionAccomplishedScreen(
          key: ValueKey(13),
          onRestart: _handleRestart,
          reportData: _reportData),
    ];

    if (screens.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final progress = (_step / (screens.length - 1)) * 100;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ProgressBar(progress: progress),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _step < screens.length
                      ? Container(
                          key: ValueKey(_step),
                          child: screens[_step],
                        )
                      : const Center(
                          key: ValueKey("lesson_complete"),
                          child: Text("Lesson Complete!")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
