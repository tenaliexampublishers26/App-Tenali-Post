import 'package:flutter/material.dart';

class McqFormValues {
  final String questionKey;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String explanation;

  const McqFormValues({
    required this.questionKey,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanation = '',
  });

  Map<String, dynamic> toRowMap() => {
        'question_key': questionKey,
        'question_text': questionText,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_option': correctOption,
        'explanation': explanation,
      };
}

/// Shared mobile bottom sheet for adding or editing a single MCQ question.
Future<McqFormValues?> showMcqQuestionFormSheet(
  BuildContext context, {
  required String title,
  String initialKey = '',
  String initialQuestion = '',
  String initialOptionA = '',
  String initialOptionB = '',
  String initialOptionC = '',
  String initialOptionD = '',
  String initialCorrectOption = 'A',
  String initialExplanation = '',
  String submitLabel = 'Save Question',
}) {
  final keyCtrl = TextEditingController(text: initialKey);
  final qCtrl = TextEditingController(text: initialQuestion);
  final aCtrl = TextEditingController(text: initialOptionA);
  final bCtrl = TextEditingController(text: initialOptionB);
  final cCtrl = TextEditingController(text: initialOptionC);
  final dCtrl = TextEditingController(text: initialOptionD);
  final expCtrl = TextEditingController(text: initialExplanation);
  var correct = const ['A', 'B', 'C', 'D'].contains(initialCorrectOption.toUpperCase())
      ? initialCorrectOption.toUpperCase()
      : 'A';
  String? validationError;

  return showModalBottomSheet<McqFormValues>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(labelText: 'Question Key (e.g. Q1)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Question Text *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: aCtrl,
                decoration: const InputDecoration(labelText: 'Option A *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bCtrl,
                decoration: const InputDecoration(labelText: 'Option B *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cCtrl,
                decoration: const InputDecoration(labelText: 'Option C *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dCtrl,
                decoration: const InputDecoration(labelText: 'Option D *'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: correct,
                decoration: const InputDecoration(labelText: 'Correct Option *'),
                items: const ['A', 'B', 'C', 'D']
                    .map((o) => DropdownMenuItem(value: o, child: Text('Option $o')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => correct = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: expCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Explanation (Optional)'),
              ),
              if (validationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  validationError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (qCtrl.text.trim().isEmpty ||
                      aCtrl.text.trim().isEmpty ||
                      bCtrl.text.trim().isEmpty ||
                      cCtrl.text.trim().isEmpty ||
                      dCtrl.text.trim().isEmpty) {
                    setModalState(() {
                      validationError = 'Question text and all 4 options (A–D) are required.';
                    });
                    return;
                  }
                  Navigator.pop(
                    ctx,
                    McqFormValues(
                      questionKey: keyCtrl.text.trim(),
                      questionText: qCtrl.text.trim(),
                      optionA: aCtrl.text.trim(),
                      optionB: bCtrl.text.trim(),
                      optionC: cCtrl.text.trim(),
                      optionD: dCtrl.text.trim(),
                      correctOption: correct,
                      explanation: expCtrl.text.trim(),
                    ),
                  );
                },
                child: Text(submitLabel),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
