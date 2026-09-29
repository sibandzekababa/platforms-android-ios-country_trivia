import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../models/option_status.dart';
import '../providers/quiz_provider.dart';
import '../widgets/option_button.dart';
import '../widgets/score_header.dart';
import 'game_completed_screen.dart';

/// Main quiz screen: shows the flag, answer options, and score header.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flag Trivia'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quiz, _) {
          if (quiz.status == QuizStatus.completed) {
            return const GameCompletedScreen();
          }

          final country = quiz.correctCountry;
          if (country == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Score / progress / attempts header.
                ScoreHeader(quiz: quiz),
                const SizedBox(height: 24),

                // Flag image.
                Expanded(
                  flex: 3,
                  child: _FlagCard(flagUrl: country.flagUrl),
                ),
                const SizedBox(height: 16),

                // Question prompt.
                Text(
                  'Which country does this flag belong to?',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Hint button.
                if (!quiz.answered && !quiz.hintUsed && quiz.remainingAttempts > 1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final used = quiz.useHint();
                        if (used) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('50/50 hint used — 2 options eliminated'),
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('50/50 Hint'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],

                // Answer options.
                Expanded(
                  flex: 4,
                  child: ListView.separated(
                    itemCount: quiz.options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = quiz.options[index];
                      return OptionButton(
                        country: option,
                        status: _optionStatus(quiz, option),
                        onTap: () => _handleTap(context, quiz, option),
                      );
                    },
                  ),
                ),

                // "Next" button appears after the question is answered.
                if (quiz.answered) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => quiz.nextQuestion(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        quiz.isPoolExhausted ? 'See Results' : 'Next Flag',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, QuizProvider quiz, country) {
    final isCorrect = quiz.selectOption(country.isoCode);

    if (!isCorrect && quiz.remainingAttempts > 0) {
      // Brief feedback for a wrong answer that still has attempts left.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wrong! ${quiz.remainingAttempts} attempt(s) left.',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  OptionStatus _optionStatus(QuizProvider quiz, Country country) {
    if (!quiz.answered) {
      if (quiz.eliminatedIsoCodes.contains(country.isoCode)) {
        return OptionStatus.disabled;
      }
      return OptionStatus.idle;
    }

    if (country.isoCode == quiz.correctCountry?.isoCode) {
      return OptionStatus.correct;
    }
    if (country.isoCode == quiz.selectedIsoCode) {
      return OptionStatus.wrong;
    }
    return OptionStatus.disabled;
  }
}

class _FlagCard extends StatelessWidget {
  const _FlagCard({required this.flagUrl});

  final String flagUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Image.network(
          flagUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Flag failed to load', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
