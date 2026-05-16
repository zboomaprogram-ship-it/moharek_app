import 'package:flutter/services.dart';

class HapticService {
  /// A light tap, good for button presses or toggles.
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// A medium impact, good for list item selections.
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// A heavy impact, good for major actions.
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// A success vibration pattern.
  static void success() {
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.vibrate();
    });
  }

  /// A selection click sound/feel.
  static void selection() {
    HapticFeedback.selectionClick();
  }
}
