import 'dart:async';
import 'package:flutter/material.dart';
import '../models/live_test.dart';
import '../models/question.dart';
import '../services/data_service.dart';

class LiveTestProvider extends ChangeNotifier {
  final DataService _service = DataService();

  List<LiveTest> _liveTests = [];
  LiveTest? _currentTest;
  List<Question> _questions = [];
  int _currentIndex = 0;

  final Map<String, String> _selectedAnswers = {}; // questionId -> option ('A', 'B', 'C', 'D')
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmitted = false;
  LiveTestSubmission? _lastSubmission;

  bool _isLoading = false;
  String? _errorMessage;

  List<LiveTest> get liveTests => _liveTests;
  LiveTest? get currentTest => _currentTest;
  List<Question> get questions => _questions;
  int get currentIndex => _currentIndex;
  Map<String, String> get selectedAnswers => _selectedAnswers;
  int get remainingSeconds => _remainingSeconds;
  bool get isSubmitted => _isSubmitted;
  LiveTestSubmission? get lastSubmission => _lastSubmission;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Question? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  String get formattedTimeRemaining {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> loadLiveTests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _liveTests = await _service.getLiveTests();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startLiveTest(LiveTest test) async {
    _currentTest = test;
    _isSubmitted = false;
    _lastSubmission = null;
    _selectedAnswers.clear();
    _currentIndex = 0;
    _remainingSeconds = test.durationMinutes * 60;
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch questions strictly without correct answers!
      _questions = await _service.getLiveTestQuestions(test.id);
      _startTimer();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        // Auto-submit when time expires
        autoSubmitOnTimeout();
      }
    });
  }

  void selectOption(String questionId, String option) {
    if (_isSubmitted) return;
    _selectedAnswers[questionId] = option;
    notifyListeners();
  }

  void clearOption(String questionId) {
    if (_isSubmitted) return;
    _selectedAnswers.remove(questionId);
    notifyListeners();
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
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

  Future<LiveTestSubmission?> submitTest({
    required String studentName,
    required String phoneNumber,
  }) async {
    if (_isSubmitted || _currentTest == null) return null;
    _timer?.cancel();
    _isLoading = true;
    notifyListeners();

    try {
      final submission = await _service.submitLiveTest(
        testId: _currentTest!.id,
        studentName: studentName,
        phoneNumber: phoneNumber,
        answers: _selectedAnswers,
      );
      _isSubmitted = true;
      _lastSubmission = submission;
      return submission;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> autoSubmitOnTimeout() async {
    if (!_isSubmitted && _currentTest != null) {
      await submitTest(
        studentName: 'Candidate (Auto-Submitted)',
        phoneNumber: '0000000000',
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
