import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  const DateSelector({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.canDecrement = true,
    this.canIncrement = true,
    super.key,
  });
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool canDecrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.appTheme.colors.background.neutralSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        spacing: 12,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: canDecrement
                  ? context.appTheme.colors.text.title
                  : context.appTheme.colors.text.bodySubtle,
            ),
            onPressed: canDecrement ? onDecrement : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
            color: canDecrement
                ? context.appTheme.colors.text.title
                : context.appTheme.colors.text.bodySubtle,
          ),
          Text(
            value,
            style: context.appTheme.typography.body.medium.copyWith(
              color: context.appTheme.colors.text.title,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: canIncrement
                  ? context.appTheme.colors.text.body
                  : context.appTheme.colors.text.bodySubtle,
            ),
            onPressed: canIncrement ? onIncrement : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
            color: canIncrement
                ? context.appTheme.colors.text.body
                : context.appTheme.colors.text.bodySubtle,
          ),
        ],
      ),
    );
  }
}
