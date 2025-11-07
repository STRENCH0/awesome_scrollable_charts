import 'package:flutter/material.dart';

class LineLabelStyle {
  final bool enabled;
  final Color? textColor;
  final Color? containerColor;
  final double cornerRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsets padding;
  final double offsetX;
  final double offsetY;
  final bool useLineColorForText;
  final double containerAlpha;

  const LineLabelStyle({
    this.enabled = true,
    this.textColor,
    this.containerColor,
    this.cornerRadius = 8.0,
    this.fontSize = 12.0,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.offsetX = 0.0,
    this.offsetY = -12.0,
    this.useLineColorForText = true,
    this.containerAlpha = 0.1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineLabelStyle &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          textColor == other.textColor &&
          containerColor == other.containerColor &&
          cornerRadius == other.cornerRadius &&
          fontSize == other.fontSize &&
          fontWeight == other.fontWeight &&
          padding == other.padding &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY &&
          useLineColorForText == other.useLineColorForText &&
          containerAlpha == other.containerAlpha;

  @override
  int get hashCode =>
      enabled.hashCode ^
      textColor.hashCode ^
      containerColor.hashCode ^
      cornerRadius.hashCode ^
      fontSize.hashCode ^
      fontWeight.hashCode ^
      padding.hashCode ^
      offsetX.hashCode ^
      offsetY.hashCode ^
      useLineColorForText.hashCode ^
      containerAlpha.hashCode;
}
