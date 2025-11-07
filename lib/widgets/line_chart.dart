import 'dart:math';

import 'package:flutter/material.dart';
import '../models/chart_data.dart';
import '../models/line_label_style.dart';
import '../models/data_marker_style.dart';
import '../models/grid_lines_style.dart';
import '../models/scroll_physics_config.dart';
import '../models/selected_pointer_style.dart';
import '../models/x_axis_label_style.dart';
import '../models/x_axis_style.dart';
import '../models/y_axis_animation_config.dart';
import '../models/zero_line_style.dart';
import 'base/base_scrollable_chart_state.dart';
import 'base/base_chart_painter.dart';
import 'month_snap_scroll_physics.dart';

/// A scrollable line chart widget with smooth animations and extensive customization options.
///
/// [LineChart] displays one or more data series as lines on a chart with horizontal
/// scrolling capability. It supports smooth animations, custom styling, and various
/// data visualization features.
///
/// Example:
/// ```dart
/// LineChart(
///   data: LineChartData(
///     labels: [
///       ChartLabel(label: 'Jan'),
///       ChartLabel(label: 'Feb'),
///       ChartLabel(label: 'Mar'),
///     ],
///     lines: [
///       ChartLine(
///         label: 'Revenue',
///         color: Colors.blue,
///         strokeWidth: 2.0,
///         points: [
///           DataPoint(labelIndex: 0, value: 1000),
///           DataPoint(labelIndex: 1, value: 1500),
///           DataPoint(labelIndex: 2, value: 1200),
///         ],
///       ),
///     ],
///   ),
///   visibleLabels: 3,
///   smooth: true,
/// )
/// ```
class LineChart extends StatefulWidget {
  /// The data to display in the chart.
  final LineChartData data;

  /// Number of data points visible at once. Defaults to 3.
  final int visibleLabels;

  /// Style for the selected pointer vertical line.
  final SelectedPointerStyle? selectedPointerStyle;

  /// Style for the vertical grid lines.
  final GridLinesStyle? gridLinesStyle;

  /// Style for the data value labels displayed on the chart.
  final LineLabelStyle? lineLabelStyle;

  /// Style for the data point markers.
  final DataMarkerStyle? dataMarkerStyle;

  /// Style for the zero line (horizontal line at y=0).
  final ZeroLineStyle zeroLineStyle;

  /// Style for the X-axis line.
  final XAxisStyle xAxisStyle;

  /// Style for the X-axis labels.
  final XAxisLabelStyle xAxisLabelStyle;

  /// How to handle missing data points. Defaults to [MissingDataBehavior.zero].
  final MissingDataBehavior missingDataBehavior;

  /// Configuration for Y-axis range animations.
  final YAxisAnimationConfig yAxisAnimationConfig;

  /// Configuration for scroll snap physics.
  final ScrollPhysicsConfig scrollPhysicsConfig;

  /// Callback when the visible range of data points changes.
  final OnVisibleRangeChanged? onVisibleRangeChanged;

  /// Callback when the selected data point changes.
  final OnSelectedChanged? onSelectedChanged;

  /// Whether to draw smooth curves between points. Defaults to false.
  final bool smooth;

  /// Initial index to display when the chart loads.
  ///
  /// If null, the chart will start at the last data point (most recent).
  /// The value will be clamped to valid indices (0 to labels.length - 1).
  ///
  /// Example:
  /// ```dart
  /// LineChart(
  ///   data: yourData,
  ///   initialIndex: 0, // Start at the first data point
  /// )
  /// ```
  final int? initialIndex;

  const LineChart({
    super.key,
    required this.data,
    this.visibleLabels = 3,
    this.initialIndex,
    this.selectedPointerStyle,
    this.gridLinesStyle,
    this.lineLabelStyle,
    this.dataMarkerStyle,
    this.zeroLineStyle = const ZeroLineStyle(),
    this.xAxisStyle = const XAxisStyle(),
    this.xAxisLabelStyle = const XAxisLabelStyle(),
    this.missingDataBehavior = MissingDataBehavior.zero,
    this.yAxisAnimationConfig = YAxisAnimationConfig.smooth,
    this.scrollPhysicsConfig = ScrollPhysicsConfig.smooth,
    this.onVisibleRangeChanged,
    this.onSelectedChanged,
    this.smooth = false,
  });

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends BaseScrollableChartState<LineChart> {
  @override
  int get labelsLength => widget.data.labels.length;

  @override
  int get visibleLabels => widget.visibleLabels;

  @override
  int? get initialIndex => widget.initialIndex;

  @override
  YAxisAnimationConfig get yAxisAnimationConfig => widget.yAxisAnimationConfig;

  @override
  OnVisibleRangeChanged? get onVisibleRangeChanged => widget.onVisibleRangeChanged;

  @override
  OnSelectedChanged? get onSelectedChanged => widget.onSelectedChanged;

  @override
  ({double min, double max}) calculateTargetYRange(int firstVisibleIndex, int lastVisibleIndex) {
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    final previousValues = <String, double>{};

    for (int labelIndex = 0; labelIndex < firstVisibleIndex; labelIndex++) {
      for (final line in widget.data.lines) {
        final pointOrNull = line.points.where((p) => p.labelIndex == labelIndex).firstOrNull;
        if (pointOrNull != null) {
          previousValues[line.label] = pointOrNull.value;
        }
      }
    }

    for (int labelIndex = firstVisibleIndex; labelIndex <= lastVisibleIndex; labelIndex++) {
      for (final line in widget.data.lines) {
        final pointOrNull = line.points.where((p) => p.labelIndex == labelIndex).firstOrNull;

        final double value;
        if (pointOrNull != null) {
          value = pointOrNull.value;
          previousValues[line.label] = value;
        } else {
          if (widget.missingDataBehavior == MissingDataBehavior.previousValue && previousValues.containsKey(line.label)) {
            value = previousValues[line.label]!;
          } else {
            value = 0.0;
          }
        }

        if (value < minValue) minValue = value;
        if (value > maxValue) maxValue = value;
      }
    }

    if (minValue == double.infinity) minValue = 0.0;
    if (maxValue == double.negativeInfinity) maxValue = 0.0;

    final padding = (maxValue - minValue) * 0.1;
    return (
      min: minValue >= 0 ? 0.0 : minValue - padding,
      max: maxValue + padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalLabels = widget.data.labels.length;
    final itemWidth = screenWidth / widget.visibleLabels;
    final paddingWidth = (widget.visibleLabels - 1) * itemWidth;
    final totalWidth = (totalLabels * itemWidth) + (2 * paddingWidth);

    final centerOffset = calculateCenterOffset();
    final minScrollBound = max(0.0, paddingWidth - (centerOffset * itemWidth));
    final maxScrollBound = paddingWidth + ((totalLabels - 1 - centerOffset) * itemWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          physics: MonthSnapScrollPhysics(
            itemWidth: itemWidth,
            scrollPhysicsConfig: widget.scrollPhysicsConfig,
            minScrollBound: minScrollBound,
            maxScrollBound: maxScrollBound,
          ),
          child: CustomPaint(
            size: Size(totalWidth, height),
            painter: LineChartPainter(
              data: widget.data,
              visibleLabels: widget.visibleLabels,
              scrollOffset: scrollOffset,
              totalWidth: totalWidth,
              itemWidth: itemWidth,
              selectedPointerStyle: widget.selectedPointerStyle,
              gridLinesStyle: widget.gridLinesStyle,
              lineLabelStyle: widget.lineLabelStyle,
              dataMarkerStyle: widget.dataMarkerStyle,
              zeroLineStyle: widget.zeroLineStyle,
              xAxisStyle: widget.xAxisStyle,
              xAxisLabelStyle: widget.xAxisLabelStyle,
              missingDataBehavior: widget.missingDataBehavior,
              animatedYMin: currentYMin,
              animatedYMax: currentYMax,
              smooth: widget.smooth,
            ),
          ),
        );
      },
    );
  }
}

class LineChartPainter extends BaseChartPainter {
  final LineChartData data;
  final double totalWidth;
  final LineLabelStyle? lineLabelStyle;
  final MissingDataBehavior missingDataBehavior;
  final double animatedYMin;
  final double animatedYMax;
  final bool smooth;

  LineChartPainter({
    required this.data,
    required super.visibleLabels,
    required super.scrollOffset,
    required this.totalWidth,
    required super.itemWidth,
    super.selectedPointerStyle,
    super.gridLinesStyle,
    this.lineLabelStyle,
    super.dataMarkerStyle,
    required super.zeroLineStyle,
    required super.xAxisStyle,
    required super.xAxisLabelStyle,
    required this.missingDataBehavior,
    required this.animatedYMin,
    required this.animatedYMax,
    required this.smooth,
  });

  @override
  List<ChartLabel> get labels => data.labels;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.lines.isEmpty || data.labels.isEmpty) return;

    final paddingWidth = (visibleLabels - 1) * itemWidth;
    final chartArea = Rect.fromLTWH(paddingWidth, 40, data.labels.length * itemWidth, size.height - 80);

    final lineData = _calculateLineData();
    final yRange = (animatedYMin != 0.0 || animatedYMax != 0.0)
        ? (min: animatedYMin, max: animatedYMax)
        : _calculateVisibleYRange(lineData);

    drawGridLines(canvas, chartArea);
    _drawLines(canvas, chartArea, itemWidth, lineData, yRange);
    drawZeroLine(canvas, chartArea, yRange);

    if (selectedPointerStyle != null) {
      drawSelectedPointer(canvas, chartArea);
    }

    drawXAxis(canvas, chartArea);
    drawXLabels(canvas, chartArea);
    _drawLineLabels(canvas, chartArea, itemWidth, lineData, yRange);
    _drawDataMarkers(canvas, chartArea, itemWidth, lineData, yRange);
  }

  List<List<double>> _calculateLineData() {
    final result = <List<double>>[];
    final previousValues = <String, double>{};

    for (int labelIndex = 0; labelIndex < data.labels.length; labelIndex++) {
      final values = <double>[];

      for (final line in data.lines) {
        final pointOrNull = line.points.where((p) => p.labelIndex == labelIndex).firstOrNull;

        final double value;
        if (pointOrNull != null) {
          value = pointOrNull.value;
          previousValues[line.label] = value;
        } else {
          if (missingDataBehavior == MissingDataBehavior.previousValue && previousValues.containsKey(line.label)) {
            value = previousValues[line.label]!;
          } else {
            value = 0.0;
          }
        }
        values.add(value);
      }
      result.add(values);
    }

    return result;
  }

  ({double min, double max}) _calculateVisibleYRange(List<List<double>> lineData) {
    final paddingWidth = (visibleLabels - 1) * itemWidth;
    final firstVisibleIndex = ((scrollOffset - paddingWidth) / itemWidth)
        .floor()
        .clamp(0, data.labels.length - 1);
    final lastVisibleIndex = (firstVisibleIndex + visibleLabels - 1)
        .clamp(0, data.labels.length - 1);

    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;

    for (int i = firstVisibleIndex; i <= lastVisibleIndex; i++) {
      if (i >= lineData.length) break;

      for (final value in lineData[i]) {
        if (value < minValue) minValue = value;
        if (value > maxValue) maxValue = value;
      }
    }

    if (minValue == double.infinity) minValue = 0.0;
    if (maxValue == double.negativeInfinity) maxValue = 0.0;

    final padding = (maxValue - minValue) * 0.1;
    return (
      min: minValue >= 0 ? 0.0 : minValue - padding,
      max: maxValue + padding,
    );
  }

  void _drawLines(
    Canvas canvas,
    Rect chartArea,
    double itemWidth,
    List<List<double>> lineData,
    ({double min, double max}) yRange,
  ) {
    final yScale = chartArea.height / (yRange.max - yRange.min);

    for (int lineIndex = 0; lineIndex < data.lines.length; lineIndex++) {
      final line = data.lines[lineIndex];
      final path = Path();

      final points = <Offset>[];
      for (int labelIndex = 0; labelIndex < data.labels.length; labelIndex++) {
        final x = chartArea.left + (labelIndex * itemWidth) + (itemWidth / 2);
        final value = lineData[labelIndex][lineIndex];
        final y = chartArea.top + ((yRange.max - value) * yScale);
        points.add(Offset(x, y));
      }

      if (points.isEmpty) continue;

      path.moveTo(points[0].dx, points[0].dy);

      if (smooth && points.length > 2) {
        for (int i = 0; i < points.length - 1; i++) {
          final p0 = i > 0 ? points[i - 1] : points[i];
          final p1 = points[i];
          final p2 = points[i + 1];
          final p3 = i < points.length - 2 ? points[i + 2] : p2;

          final tension = 0.3;

          final cp1x = p1.dx + (p2.dx - p0.dx) * tension;
          final cp1y = p1.dy + (p2.dy - p0.dy) * tension;

          final cp2x = p2.dx - (p3.dx - p1.dx) * tension;
          final cp2y = p2.dy - (p3.dy - p1.dy) * tension;

          path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
        }
      } else {
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
      }

      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, paint);
    }
  }

  void _drawLineLabels(
    Canvas canvas,
    Rect chartArea,
    double itemWidth,
    List<List<double>> lineData,
    ({double min, double max}) yRange,
  ) {
    if (lineData.isEmpty || lineLabelStyle == null || !lineLabelStyle!.enabled) return;

    final yScale = chartArea.height / (yRange.max - yRange.min);
    final style = lineLabelStyle!;

    for (int labelIndex = 0; labelIndex < data.labels.length; labelIndex++) {
      for (int lineIndex = 0; lineIndex < data.lines.length; lineIndex++) {
        final line = data.lines[lineIndex];
        final value = lineData[labelIndex][lineIndex];

        final x = chartArea.left + (labelIndex * itemWidth) + (itemWidth / 2);
        final y = chartArea.top + ((yRange.max - value) * yScale);

        final textColor = style.useLineColorForText ? line.color : (style.textColor ?? Colors.black87);
        final containerColor = style.containerColor ?? line.color.withValues(alpha: style.containerAlpha);

        final textSpan = TextSpan(
          text: value.toStringAsFixed(0),
          style: TextStyle(
            color: textColor,
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        final containerWidth = textPainter.width + style.padding.horizontal;
        final containerHeight = textPainter.height + style.padding.vertical;

        final yOffset = style.offsetY;

        final containerRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + style.offsetX, y + yOffset),
            width: containerWidth,
            height: containerHeight,
          ),
          Radius.circular(style.cornerRadius),
        );

        final containerPaint = Paint()
          ..color = containerColor
          ..style = PaintingStyle.fill;

        canvas.drawRRect(containerRect, containerPaint);

        textPainter.paint(
          canvas,
          Offset(
            x + style.offsetX - textPainter.width / 2,
            y + yOffset - textPainter.height / 2,
          ),
        );
      }
    }
  }

  void _drawDataMarkers(
    Canvas canvas,
    Rect chartArea,
    double itemWidth,
    List<List<double>> lineData,
    ({double min, double max}) yRange,
  ) {
    if (lineData.isEmpty || dataMarkerStyle == null) return;

    final yScale = chartArea.height / (yRange.max - yRange.min);
    final style = dataMarkerStyle!;

    for (int labelIndex = 0; labelIndex < data.labels.length; labelIndex++) {
      for (int lineIndex = 0; lineIndex < data.lines.length; lineIndex++) {
        final line = data.lines[lineIndex];
        final value = lineData[labelIndex][lineIndex];

        final x = chartArea.left + (labelIndex * itemWidth) + (itemWidth / 2);
        final y = chartArea.top + ((yRange.max - value) * yScale);

        final markerStyle = DataMarkerStyle(
          type: style.type,
          color: line.color,
          borderColor: style.borderColor,
          borderWidth: style.borderWidth,
          width: style.width,
          height: style.height,
        );

        switch (markerStyle.type) {
          case DataMarkerType.circle:
            drawCircleMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.rectangle:
            drawRectangleMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.diamond:
            drawDiamondMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.triangle:
            drawTriangleMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.invertedTriangle:
            drawInvertedTriangleMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.pentagon:
            drawPentagonMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.verticalLine:
            drawVerticalLineMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.horizontalLine:
            drawHorizontalLineMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.image:
            drawCircleMarker(canvas, x, y, markerStyle);
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.data != data ||
        oldDelegate.visibleLabels != visibleLabels ||
        oldDelegate.itemWidth != itemWidth ||
        oldDelegate.selectedPointerStyle != selectedPointerStyle ||
        oldDelegate.gridLinesStyle != gridLinesStyle ||
        oldDelegate.lineLabelStyle != lineLabelStyle ||
        oldDelegate.dataMarkerStyle != dataMarkerStyle ||
        oldDelegate.missingDataBehavior != missingDataBehavior ||
        oldDelegate.animatedYMin != animatedYMin ||
        oldDelegate.animatedYMax != animatedYMax ||
        oldDelegate.smooth != smooth;
  }
}
