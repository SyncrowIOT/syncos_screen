import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  TextStyle get bodyLarge => Theme.of(this).textTheme.bodyLarge!;

  TextStyle get bodyMedium => Theme.of(this).textTheme.bodyMedium!;

  TextStyle get bodySmall => Theme.of(this).textTheme.bodySmall!;
}
