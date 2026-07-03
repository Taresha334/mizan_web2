// filepath: lib/core/utils/responsive_layout.dart
import 'package:flutter/material.dart';

class ResponsiveLayout {
  /// Mobile: Screens less than 600px wide (Most Phones)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Tablet: Screens between 600px and 1024px (iPads/Tablets)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  /// Desktop: Screens 1024px and wider (Laptops/Monitors)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  /// Returns a width that feels "Natural" for forms.
  /// Stops the form from stretching to the edges on ultra-wide monitors.
  static double getOptimalWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1024) return 700; // Desktop
    if (width >= 600) return 550; // Tablet
    return width; // Mobile (Full Width)
  }
}
