import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/country.dart';
import '../services/country_service.dart';

/// Possible states of the quiz lifecycle.
enum QuizStatus { loading, error, ready, playing, completed }

/// Manages all quiz state: country pool, questions, scoring, and progress.
class QuizProvider extends ChangeNotifier {
  QuizProvider({CountryService? countryService})
      : _countryService = countryService ?? CountryService();

  final CountryService _countryService;
  final Random _random = Random();

  // ── Scoring constants ──────────────────────────────────────────────
  static const int pointsFirstAttempt = 10;
  static const int pointsSecondAttempt = 8;
  static const int pointsThirdAttempt = 5;
  static const int maxAttempts = 3;

  // ── State ──────────────────────────────────────────────────────────
  QuizStatus _status = QuizStatus.loading;
  String? _errorMessage;

  List<Country> _allCountries = [];
  final Set<String> _solvedIsoCodes = {};

  Country? _correctCountry;
  List<Country> _options = [];
  int _attemptsUsed = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedIsoCode;
  int _currentStreak = 0;
  int _bestStreak = 0;

  // ── Getters ────────────────────────────────────────────────────────
  QuizStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Country? get correctCountry => _correctCountry;
  List<Country> get options => List.unmodifiable(_options);
  int get attemptsUsed => _attemptsUsed;
  int get remainingAttempts => maxAttempts - _attemptsUsed;
  int get score => _score;
  bool get answered => _answered;
  String? get selectedIsoCode => _selectedIsoCode;

  int get totalCountries => _allCountries.length;
  int get solvedCount => _solvedIsoCodes.length;
  bool get isPoolExhausted => _solvedIsoCodes.length >= _allCountries.length;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;

  // ── Public API ─────────────────────────────────────────────────────

  /// Fetches countries from the API and prepares the first question.
  Future<void> loadGame() async {
    _status = QuizStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _allCountries = await _countryService.fetchCountries();
      _solvedIsoCodes.clear();
      _score = 0;
      _generateQuestion();
      _status = QuizStatus.ready;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = QuizStatus.error;
    }
    notifyListeners();
  }

  /// Starts the game from the ready state.
  void startGame() {
    if (_status == QuizStatus.ready) {
      _status = QuizStatus.playing;
      notifyListeners();
    }
  }

  /// Resets everything and starts a fresh game.
  Future<void> resetGame() async {
    _status = QuizStatus.loading;
    _errorMessage = null;
    _score = 0;
    _solvedIsoCodes.clear();
    _correctCountry = null;
    _options = [];
    _attemptsUsed = 0;
    _answered = false;
    _selectedIsoCode = null;
    notifyListeners();
    await loadGame();
  }

  /// Handles the user's answer selection.
  /// Returns true if the answer was correct, false otherwise.
  bool selectOption(String isoCode) {
    if (_answered || _status != QuizStatus.playing) return false;

    _selectedIsoCode = isoCode;
    _attemptsUsed++;

    final isCorrect = isoCode == _correctCountry?.isoCode;

    if (isCorrect) {
      _answered = true;
      _currentStreak++;
      if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;

      // Base points + streak bonus (2 points per streak level, max +10).
      final basePoints = _pointsForAttempt(_attemptsUsed);
      final streakBonus = _currentStreak <= 5 ? (_currentStreak - 1) * 2 : 10;
      _score += basePoints + streakBonus;
      _solvedIsoCodes.add(_correctCountry!.isoCode);
    } else if (_attemptsUsed >= maxAttempts) {
      // Out of attempts — reveal the answer, mark as solved, reset streak.
      _answered = true;
      _currentStreak = 0;
      _solvedIsoCodes.add(_correctCountry!.isoCode);
    }

    notifyListeners();
    return isCorrect;
  }

  /// Advances to the next question or completes the game.
  void nextQuestion() {
    if (!_answered) return;

    if (isPoolExhausted) {
      _status = QuizStatus.completed;
      notifyListeners();
      return;
    }

    _generateQuestion();
    _status = QuizStatus.playing;
    notifyListeners();
  }

  // ── Private helpers ─────────────────────────────────────────────────

  int _pointsForAttempt(int attempt) {
    switch (attempt) {
      case 1:
        return pointsFirstAttempt;
      case 2:
        return pointsSecondAttempt;
      case 3:
        return pointsThirdAttempt;
      default:
        return 0;
    }
  }

  void _generateQuestion() {
    final pool =
        _allCountries.where((c) => !_solvedIsoCodes.contains(c.isoCode)).toList();

    if (pool.isEmpty) {
      _status = QuizStatus.completed;
      return;
    }

    // Pick the correct answer.
    _correctCountry = pool[_random.nextInt(pool.length)];

    // Pick 3 distinct incorrect options from the remaining pool.
    final incorrectPool =
        pool.where((c) => c.isoCode != _correctCountry!.isoCode).toList();
    incorrectPool.shuffle(_random);
    final incorrectOptions = incorrectPool.take(3).toList();

    // Combine and shuffle all 4 options.
    _options = [...incorrectOptions, _correctCountry!]..shuffle(_random);

    _attemptsUsed = 0;
    _answered = false;
    _selectedIsoCode = null;
    _currentStreak = 0;
  }
}
