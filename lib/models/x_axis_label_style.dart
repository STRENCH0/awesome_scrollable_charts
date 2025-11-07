import 'package:flutter/material.dart';

class XAxisLabelStyle {
  final bool enabled;
  final Color color;
  final double fontSize;
  final FontWeight? fontWeight;
  final double distanceFromAxis;

  const XAxisLabelStyle({
    this.enabled = true,
    this.color = Colors.black87,
    this.fontSize = 12.0,
    this.fontWeight,
    this.distanceFromAxis = 8.0,
  });
}
