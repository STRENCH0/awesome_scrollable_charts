import 'package:flutter/material.dart';
import 'label_overlap_behavior.dart';

class LineLabelStyle {
  final bool enabled;
  final TextStyle textStyle;
  final Color? containerColor;
  final double cornerRadius;
  final EdgeInsets padding;
  final double offsetX;
  final double offsetY;
  final bool useLineColorForText;
  final double containerAlpha;
  final LabelOverlapBehavior overlapBehavior;

  const LineLabelStyle({
    this.enabled = true,
    this.textStyle = const TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
    ),
    this.containerColor,
    this.cornerRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.offsetX = 0.0,
    this.offsetY = -12.0,
    this.useLineColorForText = true,
    this.containerAlpha = 0.1,
    this.overlapBehavior = LabelOverlapBehavior.none,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineLabelStyle &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          textStyle == other.textStyle &&
          containerColor == other.containerColor &&
          cornerRadius == other.cornerRadius &&
          padding == other.padding &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY &&
          useLineColorForText == other.useLineColorForText &&
          containerAlpha == other.containerAlpha &&
          overlapBehavior == other.overlapBehavior;

  @override
  int get hashCode =>
      enabled.hashCode ^
      textStyle.hashCode ^
      containerColor.hashCode ^
      cornerRadius.hashCode ^
      padding.hashCode ^
      offsetX.hashCode ^
      offsetY.hashCode ^
      useLineColorForText.hashCode ^
      containerAlpha.hashCode ^
      overlapBehavior.hashCode;
}
