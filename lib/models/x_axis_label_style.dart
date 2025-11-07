import 'package:flutter/material.dart';

class XAxisLabelStyle {
  final bool enabled;
  final TextStyle textStyle;
  final double distanceFromAxis;

  const XAxisLabelStyle({
    this.enabled = true,
    this.textStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 12.0,
    ),
    this.distanceFromAxis = 8.0,
  });
}
