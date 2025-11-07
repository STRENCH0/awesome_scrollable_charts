import 'package:flutter/material.dart';

class CumulativeLabelStyle {
  final TextStyle textStyle;
  final Color containerColor;
  final double cornerRadius;
  final EdgeInsets padding;
  final double offsetX;
  final double offsetY;

  const CumulativeLabelStyle({
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    ),
    this.containerColor = Colors.black87,
    this.cornerRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.offsetX = 0.0,
    this.offsetY = -10.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CumulativeLabelStyle &&
          runtimeType == other.runtimeType &&
          textStyle == other.textStyle &&
          containerColor == other.containerColor &&
          cornerRadius == other.cornerRadius &&
          padding == other.padding &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY;

  @override
  int get hashCode =>
      textStyle.hashCode ^
      containerColor.hashCode ^
      cornerRadius.hashCode ^
      padding.hashCode ^
      offsetX.hashCode ^
      offsetY.hashCode;
}
