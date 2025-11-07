import 'package:flutter/material.dart';

enum DataMarkerType {
  circle,
  rectangle,
  image,
  pentagon,
  verticalLine,
  horizontalLine,
  diamond,
  triangle,
  invertedTriangle,
}

class DataMarkerStyle {
  final DataMarkerType type;
  final Color color;
  final Color borderColor;
  final double height;
  final double width;
  final double borderWidth;
  final String? imagePath;

  const DataMarkerStyle({
    this.type = DataMarkerType.circle,
    this.color = Colors.white,
    this.borderColor = Colors.black,
    this.height = 8.0,
    this.width = 8.0,
    this.borderWidth = 2.0,
    this.imagePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataMarkerStyle &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          color == other.color &&
          borderColor == other.borderColor &&
          height == other.height &&
          width == other.width &&
          borderWidth == other.borderWidth &&
          imagePath == other.imagePath;

  @override
  int get hashCode =>
      type.hashCode ^
      color.hashCode ^
      borderColor.hashCode ^
      height.hashCode ^
      width.hashCode ^
      borderWidth.hashCode ^
      imagePath.hashCode;
}
