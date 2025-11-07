import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/chart_data.dart';
import '../../models/data_marker_style.dart';
import '../../models/grid_lines_style.dart';
import '../../models/selected_pointer_style.dart';
import '../../models/x_axis_label_style.dart';
import '../../models/x_axis_style.dart';
import '../../models/zero_line_style.dart';

abstract class BaseChartPainter extends CustomPainter {
  final int visibleLabels;
  final double scrollOffset;
  final double itemWidth;
  final SelectedPointerStyle? selectedPointerStyle;
  final GridLinesStyle? gridLinesStyle;
  final DataMarkerStyle? dataMarkerStyle;
  final ZeroLineStyle zeroLineStyle;
  final XAxisStyle xAxisStyle;
  final XAxisLabelStyle xAxisLabelStyle;

  BaseChartPainter({
    required this.visibleLabels,
    required this.scrollOffset,
    required this.itemWidth,
    this.selectedPointerStyle,
    this.gridLinesStyle,
    this.dataMarkerStyle,
    required this.zeroLineStyle,
    required this.xAxisStyle,
    required this.xAxisLabelStyle,
  });

  List<ChartLabel> get labels;

  void drawGridLines(Canvas canvas, Rect chartArea) {
    if (gridLinesStyle == null) return;

    final paint = Paint()
      ..color = gridLinesStyle!.color
      ..strokeWidth = gridLinesStyle!.width
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < labels.length; i++) {
      final x = chartArea.left + (i * itemWidth) + (itemWidth / 2);

      if (gridLinesStyle!.isDashed) {
        drawDashedVerticalLine(
          canvas,
          Offset(x, chartArea.top),
          Offset(x, chartArea.bottom),
          paint,
          gridLinesStyle!.dashLength,
          gridLinesStyle!.dashGap,
        );
      } else {
        canvas.drawLine(
          Offset(x, chartArea.top),
          Offset(x, chartArea.bottom),
          paint,
        );
      }
    }
  }

  void drawZeroLine(
    Canvas canvas,
    Rect chartArea,
    ({double min, double max}) yRange,
  ) {
    if (!zeroLineStyle.enabled) return;
    if (yRange.min >= 0 || yRange.max <= 0) return;

    final yScale = chartArea.height / (yRange.max - yRange.min);
    final zeroY = chartArea.top + (yRange.max * yScale);

    final paint = Paint()
      ..color = zeroLineStyle.color
      ..strokeWidth = zeroLineStyle.width
      ..style = PaintingStyle.stroke;

    final startPoint = Offset(chartArea.left, zeroY);
    final endPoint = Offset(chartArea.right, zeroY);

    if (zeroLineStyle.isDashed) {
      drawDashedHorizontalLine(
        canvas,
        startPoint,
        endPoint,
        paint,
        zeroLineStyle.dashLength,
        zeroLineStyle.dashGap,
      );
    } else {
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  void drawSelectedPointer(Canvas canvas, Rect chartArea) {
    if (selectedPointerStyle == null) return;

    final paddingWidth = (visibleLabels - 1) * itemWidth;

    final double centerOffset;
    if (visibleLabels % 2 == 0) {
      centerOffset = (visibleLabels - 2) / 2.0;
    } else {
      centerOffset = (visibleLabels - 1) / 2.0;
    }

    final selectedIndex = ((scrollOffset - paddingWidth) / itemWidth + centerOffset)
        .round()
        .clamp(0, labels.length - 1);

    final x = chartArea.left + (selectedIndex * itemWidth) + (itemWidth / 2);

    final paint = Paint()
      ..color = selectedPointerStyle!.color
      ..strokeWidth = selectedPointerStyle!.width
      ..style = PaintingStyle.stroke;

    if (selectedPointerStyle!.isDashed) {
      drawDashedVerticalLine(
        canvas,
        Offset(x, chartArea.top),
        Offset(x, chartArea.bottom),
        paint,
        selectedPointerStyle!.dashLength,
        selectedPointerStyle!.dashGap,
      );
    } else {
      canvas.drawLine(
        Offset(x, chartArea.top),
        Offset(x, chartArea.bottom),
        paint,
      );
    }
  }

  void drawDashedVerticalLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double dashGap,
  ) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashLength + dashGap)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startOffset = i * (dashLength + dashGap);
      final endOffset = startOffset + dashLength;

      final dashStart = Offset(
        start.dx,
        start.dy + startOffset,
      );
      final dashEnd = Offset(
        start.dx,
        start.dy + endOffset.clamp(0, distance),
      );

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  void drawDashedHorizontalLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double dashGap,
  ) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashLength + dashGap)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startOffset = i * (dashLength + dashGap);
      final endOffset = startOffset + dashLength;

      final dashStart = Offset(
        start.dx + startOffset,
        start.dy,
      );
      final dashEnd = Offset(
        start.dx + endOffset.clamp(0, distance),
        start.dy,
      );

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  void drawXAxis(Canvas canvas, Rect chartArea) {
    if (!xAxisStyle.enabled) return;

    final paint = Paint()
      ..color = xAxisStyle.color
      ..strokeWidth = xAxisStyle.width
      ..style = PaintingStyle.stroke;

    final startPoint = Offset(chartArea.left, chartArea.bottom);
    final endPoint = Offset(chartArea.right, chartArea.bottom);

    if (xAxisStyle.isDashed) {
      drawDashedHorizontalLine(
        canvas,
        startPoint,
        endPoint,
        paint,
        xAxisStyle.dashLength,
        xAxisStyle.dashGap,
      );
    } else {
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  void drawXLabels(Canvas canvas, Rect chartArea) {
    if (!xAxisLabelStyle.enabled) return;

    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      final x = chartArea.left + (i * itemWidth) + (itemWidth / 2);

      final textSpan = TextSpan(
        text: label.label,
        style: TextStyle(
          color: xAxisLabelStyle.color,
          fontSize: xAxisLabelStyle.fontSize,
          fontWeight: xAxisLabelStyle.fontWeight,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          chartArea.bottom + xAxisLabelStyle.distanceFromAxis,
        ),
      );
    }
  }

  void drawCircleMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
    final fillPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    final radius = style.width / 2;
    canvas.drawCircle(Offset(x, y), radius, fillPaint);
    if (style.borderWidth > 0) {
      canvas.drawCircle(Offset(x, y), radius, borderPaint);
    }
  }

  void drawRectangleMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
    final rect = Rect.fromCenter(
      center: Offset(x, y),
      width: style.width,
      height: style.height,
    );

    final fillPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, fillPaint);
    if (style.borderWidth > 0) {
      canvas.drawRect(rect, borderPaint);
    }
  }

  void drawDiamondMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
    final path = Path()
      ..moveTo(x, y - style.height / 2)
      ..lineTo(x + style.width / 2, y)
      ..lineTo(x, y + style.height / 2)
      ..lineTo(x - style.width / 2, y)
      ..close();

    final fillPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    if (style.borderWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }
  }

  void drawTriangleMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
    final path = Path()
      ..moveTo(x, y - style.height / 2)
      ..lineTo(x + style.width / 2, y + style.height / 2)
      ..lineTo(x - style.width / 2, y + style.height / 2)
      ..close();

    final fillPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    if (style.borderWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }
  }

  void drawInvertedTriangleMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
    final path = Path()
      ..moveTo(x, y + style.height / 2)
      ..lineTo(x + style.width / 2, y - style.height / 2)
      ..lineTo(x - style.width / 2, y - style.height / 2)
      ..close();

    final fillPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    if (style.borderWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }
  }

  void drawPentagonMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
    final path = Path();
    final radius = style.width / 2;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * 3.14159 / 180;
      final px = x + radius * cos(angle);
      final py = y + radius * sin(angle);

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    if (style.borderWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }
  }

  void drawVerticalLineMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
    final paint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, y - style.height / 2),
      Offset(x, y + style.height / 2),
      paint,
    );
  }

  void drawHorizontalLineMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
    final paint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x - style.width / 2, y),
      Offset(x + style.width / 2, y),
      paint,
    );
  }
}
