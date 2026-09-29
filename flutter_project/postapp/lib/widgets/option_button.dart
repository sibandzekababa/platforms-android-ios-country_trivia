import 'package:flutter/material.dart';

import '../models/country.dart';
import '../models/option_status.dart';

/// A single multiple-choice answer option with visual feedback states.
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.country,
    required this.status,
    required this.onTap,
  });

  final Country country;
  final OptionStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, borderColor, textColor, icon) = _resolveStyle(context);

    final isTappable = status == OptionStatus.idle;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isTappable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  country.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: textColor),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, Color, IconData?) _resolveStyle(BuildContext context) {
    switch (status) {
      case OptionStatus.idle:
        return (
          Theme.of(context).colorScheme.surface,
          Colors.grey.shade300,
          Theme.of(context).colorScheme.onSurface,
          null,
        );
      case OptionStatus.correct:
        return (Colors.green.shade50, Colors.green, Colors.green.shade900, Icons.check_circle);
      case OptionStatus.wrong:
        return (Colors.red.shade50, Colors.red, Colors.red.shade900, Icons.cancel);
      case OptionStatus.disabled:
        return (Colors.grey.shade100, Colors.grey.shade300, Colors.grey.shade500, null);
    }
  }
}
