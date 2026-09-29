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
                ScoreHeader(quiz: quiz),
                const SizedBox(height: 24),
                Expanded(
                  flex: 3,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: _FlagCard(
                      key: ValueKey(country.flagUrl),
                      flagUrl: country.flagUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Which country does this flag belong to?',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 4,
                  child: ListView.separated(
                    itemCount: quiz.options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = quiz.options[index];
                      return AnimatedOptionButton(
                        country: option,
                        status: _optionStatus(quiz, option),
                        onTap: () => _handleTap(context, quiz, option),
                        index: index,
                      );
                    },
                  ),
                ),
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

  void _handleTap(BuildContext context, QuizProvider quiz, Country country) {
    final isCorrect = quiz.selectOption(country.isoCode);

    if (!isCorrect && quiz.remainingAttempts > 0) {
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
    if (!quiz.answered) return OptionStatus.idle;

    if (country.isoCode == quiz.correctCountry?.isoCode) {
      return OptionStatus.correct;
    }
    if (country.isoCode == quiz.selectedIsoCode) {
      return OptionStatus.wrong;
    }
    return OptionStatus.disabled;
  }
}

/// Option button with slide-in animation.
class AnimatedOptionButton extends StatelessWidget {
  const AnimatedOptionButton({
    super.key,
    required this.country,
    required this.status,
    required this.onTap,
    required this.index,
  });

  final Country country;
  final OptionStatus status;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: OptionButton(
        country: country,
        status: status,
        onTap: onTap,
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  const _FlagCard({super.key, required this.flagUrl});

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
