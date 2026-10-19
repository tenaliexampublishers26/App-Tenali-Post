import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../models/chapter.dart';
import '../models/question.dart';
import '../services/supabase_service.dart';

class McqProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Exam> _exams = [];
  List<Chapter> _chapters = [];
  List<Question> _questions = [];

  Exam? _selectedExam;
  Chapter? _selectedChapter;
  String _selectedLanguage = 'en'; // 'en', 'te', 'hi'

  int _currentIndex = 0;
  final Map<int, String> _userAnswers = {}; // questionIndex -> chosenOption ('A', 'B', 'C', 'D')
  final Map<int, bool> _answerLocked = {};  // questionIndex -> isAnswered

  bool _isLoading = false;
  String? _errorMessage;

  List<Exam> get exams => _exams;
  List<Chapter> get chapters => _chapters;
  List<Question> get questions => _questions;
  Exam? get selectedExam => _selectedExam;
  Chapter? get selectedChapter => _selectedChapter;
  String get selectedLanguage => _selectedLanguage;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Question? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  String? get selectedOptionForCurrent => _userAnswers[_currentIndex];
  bool get isCurrentLocked => _answerLocked[_currentIndex] ?? false;

  int get correctAnswersCount {
    int count = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers.containsKey(i) &&
          _userAnswers[i]?.toUpperCase() == _questions[i].correctOption?.toUpperCase()) {
        count++;
      }
    }
    return count;
  }

  int get wrongAnswersCount {
    int count = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers.containsKey(i) &&
          _userAnswers[i]?.toUpperCase() != _questions[i].correctOption?.toUpperCase()) {
        count++;
      }
    }
    return count;
  }

  Future<void> loadExams() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _exams = await _service.getExams();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectExam(Exam exam) async {
    _selectedExam = exam;
    _chapters = [];
    _isLoading = true;
    notifyListeners();
    try {
      _chapters = await _service.getChapters(exam.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectChapterAndLanguage(Chapter chapter, String languageCode) async {
    _selectedChapter = chapter;
    _selectedLanguage = languageCode;
    _currentIndex = 0;
    _userAnswers.clear();
    _answerLocked.clear();
    _isLoading = true;
    notifyListeners();

    try {
      _questions = await _service.getPracticeQuestions(
        chapterId: chapter.id,
        languageCode: languageCode,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLanguage(String langCode) {
    if (_selectedLanguage != langCode) {
      _selectedLanguage = langCode;
      if (_selectedChapter != null) {
        selectChapterAndLanguage(_selectedChapter!, langCode);
      } else {
        notifyListeners();
      }
    }
  }

  void chooseOption(String option) {
    if (isCurrentLocked) return; // Answer is already submitted and locked
    _userAnswers[_currentIndex] = option;
    _answerLocked[_currentIndex] = true; // Lock immediately for instant feedback
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void resetPractice() {
    _currentIndex = 0;
    _userAnswers.clear();
    _answerLocked.clear();
    notifyListeners();
  }
}
