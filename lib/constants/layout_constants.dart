import 'package:flutter/material.dart';

/// Layout constants for consistent spacing throughout the app
class LayoutConstants {
  // Spacing values
  static const double sectionSpacing = 8.0;
  static const double containerPadding = 8.0;
  static const double sectionSpacingSmall = 4.0;

  // Margin values
  static const double defaultHorizontalMargin = 8.0;
  static const double sectionVerticalMargin = 0.0;

  // Edge insets for consistent padding
  static const double defaultPadding = 8.0;
  static const EdgeInsets defaultEdgeInsets =
      EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0);

  // Video section specific margins
  static const EdgeInsets videoSectionMargins =
      EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0);
  static const EdgeInsets sectionMargins =
      EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0);

  // SizedBox widgets for spacing
  static const SizedBox sectionSpacer = SizedBox(height: 8.0);
  static const SizedBox smallSpacer = SizedBox(height: 4.0);
}
