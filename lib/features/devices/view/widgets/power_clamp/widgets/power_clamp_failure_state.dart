import 'package:flutter/material.dart';
import 'package:syncos_screen/utils/resource_manager/color_manager.dart';

class PowerClampFailureState extends StatelessWidget {
  const PowerClampFailureState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTitle(),
            _buildErrorMessage(),
            _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Failed to Load Data',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: ColorsManager.red,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        message.isNotEmpty
            ? message
            : "We couldn't load the energy consumption data.\n"
                'Please try again.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ColorsManager.red.withValues(alpha: 0.8),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Retry'),
      style: TextButton.styleFrom(
        foregroundColor: ColorsManager.red,
      ),
    );
  }
}
