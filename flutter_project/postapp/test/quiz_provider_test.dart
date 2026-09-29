import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:postapp/models/country.dart';
import 'package:postapp/providers/quiz_provider.dart';
import 'package:postapp/services/country_service.dart';

// ── Helpers ──────────────────────────────────────────────────────────────

http.Client _mockClient(List<Map<String, dynamic>> countries) {
  return MockClient((request) async {
    final body = jsonEncode(countries);
    return http.Response(body, 200, headers: {'content-type': 'application/json'});
  });
}

List<Map<String, dynamic>> _countriesJson(int count) {
  return List.generate(count, (i) {
    final iso = 'C${i.toString().padLeft(2, '0')}';
    return {
      'name': {'common': 'Country $i'},
      'cca2': iso,
    };
  });
}

QuizProvider _providerWithCountries(int count) {
  final client = _mockClient(_countriesJson(count));
  final service = CountryService(client: client);
  return QuizProvider(countryService: service);
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  group('QuizProvider', () {
    test('loadGame fetches countries and transitions to ready', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();

      expect(provider.status, QuizStatus.ready);
      expect(provider.totalCountries, 10);
      expect(provider.solvedCount, 0);
      expect(provider.score, 0);
    });

    test('startGame transitions from ready to playing', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();
      provider.startGame();

      expect(provider.status, QuizStatus.playing);
    });

    test('awards 10 points on first attempt', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();
      provider.startGame();

      final correct = provider.correctCountry!;
      final isCorrect = provider.selectOption(correct.isoCode);

      expect(isCorrect, true);
      expect(provider.score, 10);
      expect(provider.answered, true);
      expect(provider.solvedCount, 1);
    });

    test('awards 8 points on second attempt', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();
      provider.startGame();

      final correct = provider.correctCountry!;
      final wrong = provider.options.firstWhere((o) => o.isoCode != correct.isoCode);

      provider.selectOption(wrong.isoCode);
      expect(provider.answered, false);
      expect(provider.remainingAttempts, 2);

      final isCorrect = provider.selectOption(correct.isoCode);
      expect(isCorrect, true);
      expect(provider.score, 8);
      expect(provider.solvedCount, 1);
    });

    test('awards 5 points on third attempt', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();
      provider.startGame();

      final correct = provider.correctCountry!;
      final wrongs = provider.options.where((o) => o.isoCode != correct.isoCode).toList();

      provider.selectOption(wrongs[0].isoCode);
      provider.selectOption(wrongs[1].isoCode);
      expect(provider.answered, false);
      expect(provider.remainingAttempts, 1);

      final isCorrect = provider.selectOption(correct.isoCode);
      expect(isCorrect, true);
      expect(provider.score, 5);
    });

    test('awards 0 points and reveals answer after 3 failures', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();
      provider.startGame();

      final correct = provider.correctCountry!;
      final wrongs = provider.options.where((o) => o.isoCode != correct.isoCode).toList();

      provider.selectOption(wrongs[0].isoCode);
      provider.selectOption(wrongs[1].isoCode);
      final isCorrect = provider.selectOption(wrongs[2].isoCode);

      expect(isCorrect, false);
      expect(provider.answered, true);
      expect(provider.score, 0);
      expect(provider.solvedCount, 1);
    });

    test('solved country does not appear as correct answer again', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();
      provider.startGame();

      final firstCorrect = provider.correctCountry!;
      provider.selectOption(firstCorrect.isoCode);
      provider.nextQuestion();

      expect(provider.correctCountry!.isoCode, isNot(firstCorrect.isoCode));
    });

    test('options always contain exactly 4 distinct countries', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();
      provider.startGame();

      final options = provider.options;
      expect(options.length, 4);
      final isoCodes = options.map((o) => o.isoCode).toSet();
      expect(isoCodes.length, 4);
    });

    test('game completes when all countries are exhausted', () async {
      final provider = _providerWithCountries(4);
      await provider.loadGame();
      provider.startGame();

      // Solve all 4 countries.
      for (var i = 0; i < 4; i++) {
        final correct = provider.correctCountry!;
        provider.selectOption(correct.isoCode);
        provider.nextQuestion();
      }

      expect(provider.status, QuizStatus.completed);
      expect(provider.solvedCount, 4);
      expect(provider.isPoolExhausted, true);
    });

    test('resetGame restores full pool and zero score', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();
      provider.startGame();

      // Solve a few countries.
      for (var i = 0; i < 3; i++) {
        final correct = provider.correctCountry!;
        provider.selectOption(correct.isoCode);
        provider.nextQuestion();
      }
      expect(provider.solvedCount, 3);
      expect(provider.score, greaterThan(0));

      await provider.resetGame();

      expect(provider.status, QuizStatus.ready);
      expect(provider.solvedCount, 0);
      expect(provider.score, 0);
      expect(provider.totalCountries, 10);
    });

    test('selectOption ignores taps after question is answered', () async {
      final provider = _providerWithCountries(10);
      await provider.loadGame();
      provider.startGame();

      final correct = provider.correctCountry!;
      provider.selectOption(correct.isoCode);
      expect(provider.answered, true);

      final attemptsBefore = provider.attemptsUsed;
      final wrong = provider.options.firstWhere((o) => o.isoCode != correct.isoCode);
      final result = provider.selectOption(wrong.isoCode);

      expect(result, false);
      expect(provider.attemptsUsed, attemptsBefore);
    });

    test('handles API error gracefully', () async {
      final client = MockClient((request) async {
        return http.Response('Server Error', 500);
      });
      final service = CountryService(client: client);
      final provider = QuizProvider(countryService: service);

      await provider.loadGame();

      expect(provider.status, QuizStatus.error);
      expect(provider.errorMessage, isNotNull);
    });

    test('handles network timeout gracefully', () async {
      final client = MockClient((request) async {
        throw Exception('Request timed out. Please check your connection.');
      });
      final service = CountryService(client: client);
      final provider = QuizProvider(countryService: service);

      await provider.loadGame();

      expect(provider.status, QuizStatus.error);
      expect(provider.errorMessage, contains('timed out'));
    });
  });
}
