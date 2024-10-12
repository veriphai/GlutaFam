import 'package:flutter/material.dart';

class CEREvaluationScreen extends StatefulWidget {
  final String problemStatement;
  final String selectedClaim;
  final List<String> selectedEvidences;
  final String studentReasoning;
  final String correctClaim;
  final List<String> correctEvidences;
  final String correctReasoning;

  const CEREvaluationScreen({
    Key? key,
    required this.problemStatement,
    required this.selectedClaim,
    required this.selectedEvidences,
    required this.studentReasoning,
    required this.correctClaim,
    required this.correctEvidences,
    required this.correctReasoning,
  }) : super(key: key);

  @override
  _CEREvaluationScreenState createState() => _CEREvaluationScreenState();
}

class _CEREvaluationScreenState extends State<CEREvaluationScreen> {
  bool isEvaluated = false;
  bool isClaimCorrect = false;
  List<String> incorrectEvidences = [];
  List<String> missingEvidences = [];
  bool isReasoningCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'CER Evaluation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.problemStatement,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Claim:',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              buildClaimSection(),
              const SizedBox(height: 20),
              const Text(
                'Your Evidence:',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              buildEvidenceSection(),
              const SizedBox(height: 20),
              const Text(
                'Your Reasoning:',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              buildReasoningSection(),
              const SizedBox(height: 20),
              if (!isEvaluated)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isEvaluated ? null : evaluateCER,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Evaluate CER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (isEvaluated)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                          context); // Navigate back to the chapter screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Back to Chapter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildClaimSection() {
    if (isEvaluated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isClaimCorrect ? Icons.check_circle : Icons.cancel,
                color: isClaimCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.selectedClaim,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (!isClaimCorrect)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Correct Claim:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.correctClaim,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),
        ],
      );
    } else {
      return Text(
        widget.selectedClaim,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      );
    }
  }

  Widget buildEvidenceSection() {
    if (isEvaluated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widget.selectedEvidences.asMap().entries.map((entry) {
            int index = entry.key + 1; // For sequential numbering
            String evidence = entry.value;
            bool isCorrect = widget.correctEvidences.contains(evidence);
            return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$evidence',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ));
          }).toList(),
          if (missingEvidences.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Missing Evidences:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...missingEvidences.map((evidence) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              evidence,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.selectedEvidences.asMap().entries.map((entry) {
          int index = entry.key + 1;
          String evidence = entry.value;
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '$index. $evidence',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget buildReasoningSection() {
    if (isEvaluated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isReasoningCorrect ? Icons.check_circle : Icons.cancel,
                color: isReasoningCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.studentReasoning,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          if (!isReasoningCorrect)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Correct Reasoning:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.correctReasoning,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),
        ],
      );
    } else {
      return Text(
        widget.studentReasoning,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      );
    }
  }

  void evaluateCER() {
    setState(() {
      isClaimCorrect = widget.selectedClaim == widget.correctClaim;

      // Find incorrect and missing evidences.
      incorrectEvidences = widget.selectedEvidences
          .where((evidence) => !widget.correctEvidences.contains(evidence))
          .toList();
      missingEvidences = widget.correctEvidences
          .where((evidence) => !widget.selectedEvidences.contains(evidence))
          .toList();

      // Check if the reasoning matches. This can be made more sophisticated.
      isReasoningCorrect = widget.studentReasoning.trim().toLowerCase() ==
          widget.correctReasoning.trim().toLowerCase();

      isEvaluated = true;
    });
  }
}
