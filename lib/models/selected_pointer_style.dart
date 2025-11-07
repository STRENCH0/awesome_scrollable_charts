import 'package:flutter/material.dart';

class SelectedPointerStyle {
  final Color color;
  final double width;
  final bool isDashed;
  final double dashLength;
  final double dashGap;

  const SelectedPointerStyle({
    this.color = Colors.grey,
    this.width = 1.0,
    this.isDashed = false,
    this.dashLength = 5.0,
    this.dashGap = 3.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedPointerStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          width == other.width &&
          isDashed == other.isDashed &&
          dashLength == other.dashLength &&
          dashGap == other.dashGap;

  @override
  int get hashCode =>
      color.hashCode ^
      width.hashCode ^
      isDashed.hashCode ^
      dashLength.hashCode ^
      dashGap.hashCode;
}
