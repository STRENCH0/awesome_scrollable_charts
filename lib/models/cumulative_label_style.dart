import 'package:flutter/material.dart';

class CumulativeLabelStyle {
  final Color textColor;
  final Color containerColor;
  final double cornerRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsets padding;
  final double offsetX;
  final double offsetY;

  const CumulativeLabelStyle({
    this.textColor = Colors.white,
    this.containerColor = Colors.black87,
    this.cornerRadius = 16.0,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.bold,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.offsetX = 0.0,
    this.offsetY = -10.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CumulativeLabelStyle &&
          runtimeType == other.runtimeType &&
          textColor == other.textColor &&
          containerColor == other.containerColor &&
          cornerRadius == other.cornerRadius &&
          fontSize == other.fontSize &&
          fontWeight == other.fontWeight &&
          padding == other.padding &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY;

  @override
  int get hashCode =>
      textColor.hashCode ^
      containerColor.hashCode ^
      cornerRadius.hashCode ^
      fontSize.hashCode ^
      fontWeight.hashCode ^
      padding.hashCode ^
      offsetX.hashCode ^
      offsetY.hashCode;
}
