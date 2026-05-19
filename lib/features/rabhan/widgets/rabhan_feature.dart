import 'package:flutter/material.dart';
import 'package:moharek_app/core/config/app_config.dart';

class RabhanFeature extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  const RabhanFeature({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    if (AppConfig.flavorName != 'rabhan') {
      return fallback ?? const SizedBox.shrink();
    }
    return child;
  }
}
