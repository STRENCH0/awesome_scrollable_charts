import 'package:flutter/material.dart';

class XAxisStyle {
  final bool enabled;
  final Color color;
  final double width;
  final bool isDashed;
  final double dashLength;
  final double dashGap;

  const XAxisStyle({
    this.enabled = true,
    this.color = const Color(0xFFBDBDBD), // Colors.grey.shade400
    this.width = 1.0,
    this.isDashed = false,
    this.dashLength = 5.0,
    this.dashGap = 3.0,
  });
}
