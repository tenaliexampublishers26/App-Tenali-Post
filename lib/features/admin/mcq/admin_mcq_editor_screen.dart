import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/question.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';

class AdminMcqEditorScreen extends StatefulWidget {
  final Question? questionToEdit;

  const AdminMcqEditorScreen({super.key, this.questionToEdit});

  @override
  State<AdminMcqEditorScreen> createState() => _AdminMcqEditorScreenState();
}

class _AdminMcqEditorScreenState extends State<AdminMcqEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedExamId;
  late String _selectedChapterId;
  String _activeLanguageTab = 'en'; // 'en', 'te', 'hi'
  String _difficulty = 'Medium';
  bool _isPublished = true;
  String _correctOption = 'A';

  // Language-specific controllers
  final Map<String, TextEditingController> _questionControllers = {
    'en': TextEditingController(),
    'te': TextEditingController(),
    'hi': TextEditingController(),
  };

  final Map<String, Map<String, TextEditingController>> _optionControllers = {
    'en': {
      'A': TextEditingController(),
      'B': TextEditingController(),
      'C': TextEditingController(),
      'D': TextEditingController(),
    },
    'te': {
      'A': TextEditingController(),
      'B': TextEditingController(),
      'C': TextEditingController(),
      'D': TextEditingController(),
    },
    'hi': {
      'A': TextEditingController(),
      'B': TextEditingController(),
      'C': TextEditingController(),
      'D': TextEditingController(),
    },
  };

  final Map<String, TextEditingController> _explanationControllers = {
    'en': TextEditingController(),
    'te': TextEditingController(),
    'hi': TextEditingController(),
  };

  final TextEditingController _postalRuleRefController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final admin = Provider.of<AdminProvider>(context, listen: false);

    if (widget.questionToEdit != null) {
      final q = widget.questionToEdit!;
      _selectedExamId = q.examId;
      _selectedChapterId = q.chapterId;
      _activeLanguageTab = q.languageCode;
      _difficulty = q.difficulty;
      _isPublished = q.isPublished;
      _correctOption = q.correctOption ?? 'A';

      _questionControllers[q.languageCode]?.text = q.questionText;
      _optionControllers[q.languageCode]?['A']?.text = q.optionA;
      _optionControllers[q.languageCode]?['B']?.text = q.optionB;
      _optionControllers[q.languageCode]?['C']?.text = q.optionC;
      _optionControllers[q.languageCode]?['D']?.text = q.optionD;
      _explanationControllers[q.languageCode]?.text = q.explanation ?? '';
      _postalRuleRefController.text = q.postalRuleRef ?? '';
    } else {
      _selectedExamId = admin.exams.isNotEmpty ? admin.exams.first.id : 'mts';
      final filteredChapters = admin.chapters.where((c) => c.examId == _selectedExamId).toList();
      _selectedChapterId = filteredChapters.isNotEmpty ? filteredChapters.first.id : 'ch-po-guide-1';
    }
  }

  @override
  void dispose() {
    for (var c in _questionControllers.values) {
      c.dispose();
    }
    for (var optMap in _optionControllers.values) {
      for (var c in optMap.values) {
        c.dispose();
      }
    }
    for (var c in _explanationControllers.values) {
      c.dispose();
    }
    _postalRuleRefController.dispose();
    super.dispose();
  }

  bool _isLanguageComplete(String lang) {
    final qText = _questionControllers[lang]?.text.trim() ?? '';
    final optA = _optionControllers[lang]?['A']?.text.trim() ?? '';
    final optB = _optionControllers[lang]?['B']?.text.trim() ?? '';
    final optC = _optionControllers[lang]?['C']?.text.trim() ?? '';
    final optD = _optionControllers[lang]?['D']?.text.trim() ?? '';
    return qText.isNotEmpty && optA.isNotEmpty && optB.isNotEmpty && optC.isNotEmpty && optD.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminEmail = auth.user?.email ?? 'admin@tenalipost.gov.in';

    final chaptersForExam = admin.chapters.where((c) => c.examId == _selectedExamId).toList();
    if (!chaptersForExam.any((c) => c.id == _selectedChapterId) && chaptersForExam.isNotEmpty) {
      _selectedChapterId = chaptersForExam.first.id;
    }

    final isEdit = widget.questionToEdit != null;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Question' : 'Create Question'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : TextButton.icon(
                    icon: const Icon(Icons.check_rounded, color: AppTheme.secondaryMaroon),
                    label: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.secondaryMaroon, fontSize: 16),
                    ),
                    onPressed: () => _saveQuestion(admin, adminEmail),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exam & Chapter Card
              _cardWrapper(
                title: 'Exam & Chapter Assignment',
                icon: Icons.school_rounded,
                child: Column(
                  children: [
                    // Exam Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedExamId,
                      decoration: const InputDecoration(labelText: 'Target Exam Cadre *'),
                      items: admin.exams.map((e) {
                        return DropdownMenuItem(value: e.id, child: Text('${e.code} — ${e.title}'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedExamId = val;
                            final chs = admin.chapters.where((c) => c.examId == val).toList();
                            if (chs.isNotEmpty) _selectedChapterId = chs.first.id;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Chapter Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedChapterId,
                      decoration: const InputDecoration(labelText: 'Syllabus Chapter *'),
                      items: chaptersForExam.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('Ch ${c.chapterNumber}: ${c.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedChapterId = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Multilingual Language Tabs & Completeness
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWarmWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderWarmSubtle),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Question Language & Translations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _langTab('en', 'English', true),
                        const SizedBox(width: 8),
                        _langTab('te', 'తెలుగు', false),
                        const SizedBox(width: 8),
                        _langTab('hi', 'हिन्दी', false),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Question Text & Options in Active Language
              _cardWrapper(
                title: 'Question Content (${_activeLanguageTab.toUpperCase()})',
                icon: Icons.edit_note_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _questionControllers[_activeLanguageTab],
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Question Text (${_activeLanguageTab.toUpperCase()}) *',
                        hintText: 'Enter the exact examination question clause...',
                        alignLabelWithHint: true,
                      ),
                      validator: (val) {
                        if (_activeLanguageTab == 'en' && (val == null || val.trim().isEmpty)) {
                          return 'English question text is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // 4 Options A, B, C, D
                    _optionField('A', _optionControllers[_activeLanguageTab]!['A']!),
                    const SizedBox(height: 10),
                    _optionField('B', _optionControllers[_activeLanguageTab]!['B']!),
                    const SizedBox(height: 10),
                    _optionField('C', _optionControllers[_activeLanguageTab]!['C']!),
                    const SizedBox(height: 10),
                    _optionField('D', _optionControllers[_activeLanguageTab]!['D']!),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Correct Answer Selector & Explanation
              _cardWrapper(
                title: 'Official Answer Key & Citation',
                icon: Icons.verified_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Correct Answer Option: *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['A', 'B', 'C', 'D'].map((opt) {
                        final isSelected = _correctOption == opt;
                        return ChoiceChip(
                          label: Text('Option $opt', style: TextStyle(fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                          selected: isSelected,
                          selectedColor: AppTheme.successGreen,
                          backgroundColor: AppTheme.bgWarm,
                          onSelected: (_) => setState(() => _correctOption = opt),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Postal Rule Citation
                    TextFormField(
                      controller: _postalRuleRefController,
                      decoration: const InputDecoration(
                        labelText: 'Postal Rule / Clause Reference',
                        hintText: 'e.g. PO Guide Part 1 Clause 14, Postal Manual Vol V',
                        prefixIcon: Icon(Icons.bookmark_outline_rounded, color: AppTheme.goldBell),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Explanation field
                    TextFormField(
                      controller: _explanationControllers[_activeLanguageTab],
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Official Explanation (${_activeLanguageTab.toUpperCase()})',
                        hintText: 'Provide detailed postal justification displayed to candidates post-answer...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Metadata: Difficulty & Publication Status
              _cardWrapper(
                title: 'Difficulty & Publication Status',
                icon: Icons.tune_rounded,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _difficulty,
                            decoration: const InputDecoration(labelText: 'Difficulty Level'),
                            items: const [
                              DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                              DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _difficulty = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Publish Immediately', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(
                        _isPublished ? 'Visible to students in practice & tests' : 'Saved as Draft (Admin only)',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      value: _isPublished,
                      activeThumbColor: AppTheme.successGreen,
                      onChanged: (val) => setState(() => _isPublished = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Big Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : () => _saveQuestion(admin, adminEmail),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'Update Question in Database' : 'Publish Question to Question Bank',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langTab(String code, String name, bool isRequired) {
    final isSelected = _activeLanguageTab == code;
    final isComplete = _isLanguageComplete(code);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeLanguageTab = code),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryNavy : AppTheme.bgWarm,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryNavy : (isComplete ? AppTheme.successGreen : AppTheme.borderWarmSubtle),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isComplete ? Icons.check_circle_rounded : (isRequired ? Icons.error_outline_rounded : Icons.radio_button_unchecked_rounded),
                    size: 11,
                    color: isSelected ? Colors.white70 : (isComplete ? AppTheme.successGreen : AppTheme.warningAmber),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isComplete ? 'Ready' : (isRequired ? 'Required' : 'Draft'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white70 : (isComplete ? AppTheme.successGreen : AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionField(String letter, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Option $letter',
        prefixIcon: Container(
          width: 32,
          alignment: Alignment.center,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: _correctOption == letter ? AppTheme.successGreen : AppTheme.surfaceCream,
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _correctOption == letter ? Colors.white : AppTheme.primaryNavy,
              ),
            ),
          ),
        ),
      ),
      validator: (val) {
        if (_activeLanguageTab == 'en' && (val == null || val.trim().isEmpty)) {
          return 'Option $letter is required.';
        }
        return null;
      },
    );
  }

  Widget _cardWrapper({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderWarmSubtle),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryNavy),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            ],
          ),
          const Divider(height: 20, color: AppTheme.borderWarmSubtle),
          child,
        ],
      ),
    );
  }

  Future<void> _saveQuestion(AdminProvider admin, String adminEmail) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required English fields.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentLang = _activeLanguageTab;
      final qId = widget.questionToEdit?.id ?? 'q-${DateTime.now().millisecondsSinceEpoch}';

      final question = Question(
        id: qId,
        chapterId: _selectedChapterId,
        examId: _selectedExamId,
        languageCode: currentLang,
        questionText: _questionControllers[currentLang]!.text.trim(),
        optionA: _optionControllers[currentLang]!['A']!.text.trim(),
        optionB: _optionControllers[currentLang]!['B']!.text.trim(),
        optionC: _optionControllers[currentLang]!['C']!.text.trim(),
        optionD: _optionControllers[currentLang]!['D']!.text.trim(),
        correctOption: _correctOption,
        explanation: _explanationControllers[currentLang]?.text.trim(),
        postalRuleRef: _postalRuleRefController.text.trim(),
        questionNumber: widget.questionToEdit?.questionNumber ?? (admin.questions.length + 1),
        difficulty: _difficulty,
        isPublished: _isPublished,
      );

      await admin.saveQuestion(question, adminEmail: adminEmail);

      // Also save translations if provided for Telugu or Hindi
      for (final lang in ['te', 'hi']) {
        if (lang != currentLang && _isLanguageComplete(lang)) {
          final translated = question.copyWith(
            id: '$qId-$lang',
            languageCode: lang,
            questionText: _questionControllers[lang]!.text.trim(),
            optionA: _optionControllers[lang]!['A']!.text.trim(),
            optionB: _optionControllers[lang]!['B']!.text.trim(),
            optionC: _optionControllers[lang]!['C']!.text.trim(),
            optionD: _optionControllers[lang]!['D']!.text.trim(),
            explanation: _explanationControllers[lang]?.text.trim(),
          );
          await admin.saveQuestion(translated, adminEmail: adminEmail);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.questionToEdit != null ? 'Question updated successfully!' : 'Question published to question bank!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving question: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
