import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/resource_manager/color_manager.dart';

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
        color: ColorsManager.grayBox,
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
                  ? ColorsManager.blackColor
                  : ColorsManager.greyColor,
            ),
            onPressed: canDecrement ? onDecrement : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
            color: canDecrement
                ? ColorsManager.grayColor
                : ColorsManager.greyColor,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorsManager.blackColor,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: canIncrement
                  ? ColorsManager.blackColor
                  : ColorsManager.greyColor,
            ),
            onPressed: canIncrement ? onIncrement : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
            color: canIncrement
                ? ColorsManager.grayColor
                : ColorsManager.greyColor,
          ),
        ],
      ),
    );
  }
}
