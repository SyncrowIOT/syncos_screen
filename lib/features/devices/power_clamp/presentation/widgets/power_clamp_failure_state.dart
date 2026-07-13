import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

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
            _buildTitle(context),
            _buildErrorMessage(context),
            _buildRetryButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return  Text(
      'Failed to Load Data',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.appTheme.colors.text.danger,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        message.isNotEmpty
            ? message
            : "We couldn't load the energy consumption data.\n"
                  'Please try again.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.appTheme.colors.text.danger,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Retry'),
      style: TextButton.styleFrom(
        foregroundColor:context.appTheme.colors.text.danger,
      ),
    );
  }
}
