import 'package:flutter/material.dart';

class YAxisAnimationConfig {
  final Duration duration;
  final Curve curve;

  const YAxisAnimationConfig({
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
  });

  static const YAxisAnimationConfig smooth = YAxisAnimationConfig(
    duration: Duration(milliseconds: 300),
    curve: Curves.linear,
  );

  static const YAxisAnimationConfig fast = YAxisAnimationConfig(
    duration: Duration(milliseconds: 150),
    curve: Curves.linear,
  );

  static const YAxisAnimationConfig slow = YAxisAnimationConfig(
    duration: Duration(milliseconds: 500),
    curve: Curves.easeOut,
  );

  static const YAxisAnimationConfig none = YAxisAnimationConfig(
    duration: Duration.zero,
    curve: Curves.linear,
  );
}
