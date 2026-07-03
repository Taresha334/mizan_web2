// filepath: lib/core/utils/string_diff_helper.dart
import 'package:flutter/material.dart';

class StringDiffHelper {
  /// Compares Farmer Input vs SMS Reference and highlights mismatches.
  static List<TextSpan> highlightDifferences(String input, String target) {
    List<TextSpan> spans = [];

    // We iterate based on the longer string to catch extra characters
    int maxLength = input.length > target.length ? input.length : target.length;

    for (int i = 0; i < maxLength; i++) {
      // Get the character from the farmer's input
      String char = i < input.length ? input[i] : "";

      // Check if it matches the same position in the real SMS Reference
      bool isMatch =
          i < target.length && i < input.length && input[i] == target[i];

      spans.add(
        TextSpan(
          text: char,
          style: TextStyle(
            color: isMatch ? Colors.black : Colors.red,
            fontWeight: isMatch ? FontWeight.normal : FontWeight.bold,
            // Add a subtle background to the error to make it pop
            backgroundColor: isMatch
                ? Colors.transparent
                : Colors.red.withOpacity(0.1),
          ),
        ),
      );
    }
    return spans;
  }
}
