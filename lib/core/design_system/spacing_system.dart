import 'package:flutter/material.dart';

/// Consistent spacing tokens for margins, paddings and gaps throughout the app.
abstract final class Spacing {
  Spacing._();

  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Page / screen padding
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: md, vertical: lg);
  static const EdgeInsets pagePaddingH = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets sectionPadding = EdgeInsets.all(md);

  // Card inner padding
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: md);
  static const EdgeInsets cardPaddingSm =
      EdgeInsets.symmetric(horizontal: sm + xs, vertical: sm + xs);

  // Common edge insets by size
  static EdgeInsets all(double v) => EdgeInsets.all(v);
  static EdgeInsets symmetric({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: v);
  static EdgeInsets only({
    double l = 0,
    double t = 0,
    double r = 0,
    double b = 0,
  }) =>
      EdgeInsets.only(left: l, top: t, right: r, bottom: b);

  // SizedBox helpers
  static const Widget gapXxs = SizedBox(width: xxs, height: xxs);
  static const Widget gapXs = SizedBox(width: xs, height: xs);
  static const Widget gapSm = SizedBox(width: sm, height: sm);
  static const Widget gapMd = SizedBox(width: md, height: md);
  static const Widget gapLg = SizedBox(width: lg, height: lg);
  static const Widget gapXl = SizedBox(width: xl, height: xl);

  static Widget hGap(double v) => SizedBox(width: v);
  static Widget vGap(double v) => SizedBox(height: v);
}
