import 'package:flutter/material.dart';

class ZeroLineStyle {
  final bool enabled;
  final Color color;
  final double width;
  final bool isDashed;
  final double dashLength;
  final double dashGap;

  const ZeroLineStyle({
    this.enabled = true,
    this.color = Colors.black87,
    this.width = 2.0,
    this.isDashed = false,
    this.dashLength = 5.0,
    this.dashGap = 3.0,
  });
}
