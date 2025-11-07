import 'dart:math';

import 'package:flutter/material.dart';
import '../models/chart_data.dart';
import '../models/cumulative_label_style.dart';
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

/// A scrollable stacked area chart widget for displaying cumulative data.
///
/// [StackedAreaChart] visualizes multiple data series as stacked filled areas,
/// showing how individual components contribute to a total over time. It features
/// smooth scrolling, animations, and extensive styling options.
///
/// Example:
/// ```dart
/// StackedAreaChart(
///   data: StackedAreaChartData(
///     labels: [
///       ChartLabel(label: 'Q1'),
///       ChartLabel(label: 'Q2'),
///       ChartLabel(label: 'Q3'),
///     ],
///     areas: [
///       ChartArea(
///         label: 'Product A',
///         color: Colors.blue.withOpacity(0.7),
///         points: [
///           DataPoint(labelIndex: 0, value: 500),
///           DataPoint(labelIndex: 1, value: 700),
///           DataPoint(labelIndex: 2, value: 600),
///         ],
///       ),
///     ],
///   ),
///   visibleLabels: 3,
/// )
/// ```
class StackedAreaChart extends StatefulWidget {
  /// The data to display in the chart.
  final StackedAreaChartData data;

  /// Number of data points visible at once. Defaults to 3.
  final int visibleLabels;

  /// Style for the selected pointer vertical line.
  final SelectedPointerStyle? selectedPointerStyle;

  /// Style for the vertical grid lines.
  final GridLinesStyle? gridLinesStyle;

  /// Style for the cumulative value labels at the top of each stack.
  final CumulativeLabelStyle? cumulativeLabelStyle;

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

  /// Initial index to display when the chart loads.
  ///
  /// If null, the chart will start at the last data point (most recent).
  /// The value will be clamped to valid indices (0 to labels.length - 1).
  ///
  /// Example:
  /// ```dart
  /// StackedAreaChart(
  ///   data: yourData,
  ///   initialIndex: 0, // Start at the first data point
  /// )
  /// ```
  final int? initialIndex;

  const StackedAreaChart({
    super.key,
    required this.data,
    this.visibleLabels = 3,
    this.selectedPointerStyle,
    this.gridLinesStyle,
    this.cumulativeLabelStyle,
    this.dataMarkerStyle,
    this.zeroLineStyle = const ZeroLineStyle(),
    this.xAxisStyle = const XAxisStyle(),
    this.xAxisLabelStyle = const XAxisLabelStyle(),
    this.missingDataBehavior = MissingDataBehavior.zero,
    this.yAxisAnimationConfig = YAxisAnimationConfig.smooth,
    this.scrollPhysicsConfig = ScrollPhysicsConfig.smooth,
    this.onVisibleRangeChanged,
    this.onSelectedChanged,
    this.initialIndex,
  });

  @override
  State<StackedAreaChart> createState() => _StackedAreaChartState();
}

class _StackedAreaChartState extends BaseScrollableChartState<StackedAreaChart> {
  @override
  int get labelsLength => widget.data.labels.length;

  @override
  int get visibleLabels => widget.visibleLabels;

  @override
  YAxisAnimationConfig get yAxisAnimationConfig => widget.yAxisAnimationConfig;

  @override
  OnVisibleRangeChanged? get onVisibleRangeChanged => widget.onVisibleRangeChanged;

  @override
  OnSelectedChanged? get onSelectedChanged => widget.onSelectedChanged;

  @override
  int? get initialIndex => widget.initialIndex;

  @override
  ({double min, double max}) calculateTargetYRange(int firstVisibleIndex, int lastVisibleIndex) {
    double minValue = 0.0;
    double maxValue = 0.0;
    final previousValues = <String, double>{}; // Track previous values per area

    // Build previous values from indices before visible range
    for (int labelIndex = 0; labelIndex < firstVisibleIndex; labelIndex++) {
      for (final area in widget.data.areas) {
        final pointOrNull = area.points.where((p) => p.labelIndex == labelIndex).firstOrNull;
        if (pointOrNull != null) {
          previousValues[area.label] = pointOrNull.value;
        }
      }
    }

    for (int labelIndex = firstVisibleIndex; labelIndex <= lastVisibleIndex; labelIndex++) {
      double positiveStack = 0.0;
      double negativeStack = 0.0;

      for (final area in widget.data.areas) {
        final pointOrNull = area.points.where((p) => p.labelIndex == labelIndex).firstOrNull;

        final double value;
        if (pointOrNull != null) {
          value = pointOrNull.value;
          previousValues[area.label] = value;
        } else {
          // Missing data - use configured behavior
          if (widget.missingDataBehavior == MissingDataBehavior.previousValue && previousValues.containsKey(area.label)) {
            value = previousValues[area.label]!;
          } else {
            value = 0.0;
          }
        }

        if (value >= 0) {
          positiveStack += value;
          if (positiveStack > maxValue) maxValue = positiveStack;
        } else {
          negativeStack += value;
          if (negativeStack < minValue) minValue = negativeStack;
        }
      }
    }

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
            painter: StackedAreaChartPainter(
              data: widget.data,
              visibleLabels: widget.visibleLabels,
              scrollOffset: scrollOffset,
              totalWidth: totalWidth,
              itemWidth: itemWidth,
              selectedPointerStyle: widget.selectedPointerStyle,
              gridLinesStyle: widget.gridLinesStyle,
              cumulativeLabelStyle: widget.cumulativeLabelStyle,
              dataMarkerStyle: widget.dataMarkerStyle,
              zeroLineStyle: widget.zeroLineStyle,
              xAxisStyle: widget.xAxisStyle,
              xAxisLabelStyle: widget.xAxisLabelStyle,
              missingDataBehavior: widget.missingDataBehavior,
              animatedYMin: currentYMin,
              animatedYMax: currentYMax,
            ),
          ),
        );
      },
    );
  }
}

class StackedAreaChartPainter extends BaseChartPainter {
  final StackedAreaChartData data;
  final double totalWidth;
  final CumulativeLabelStyle? cumulativeLabelStyle;
  final MissingDataBehavior missingDataBehavior;
  final double animatedYMin;
  final double animatedYMax;

  StackedAreaChartPainter({
    required this.data,
    required super.visibleLabels,
    required super.scrollOffset,
    required this.totalWidth,
    required super.itemWidth,
    super.selectedPointerStyle,
    super.gridLinesStyle,
    this.cumulativeLabelStyle,
    super.dataMarkerStyle,
    required super.zeroLineStyle,
    required super.xAxisStyle,
    required super.xAxisLabelStyle,
    required this.missingDataBehavior,
    required this.animatedYMin,
    required this.animatedYMax,
  });

  @override
  List<ChartLabel> get labels => data.labels;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.areas.isEmpty || data.labels.isEmpty) return;

    final paddingWidth = (visibleLabels - 1) * itemWidth;
    final chartArea = Rect.fromLTWH(paddingWidth, 40, data.labels.length * itemWidth, size.height - 80);

    final cumulativeData = _calculateCumulativeData();
    final yRange = (animatedYMin != 0.0 || animatedYMax != 0.0)
        ? (min: animatedYMin, max: animatedYMax)
        : _calculateVisibleYRange(cumulativeData);

    drawGridLines(canvas, chartArea);
    _drawAreas(canvas, chartArea, itemWidth, cumulativeData, yRange);
    drawZeroLine(canvas, chartArea, yRange);

    if (selectedPointerStyle != null) {
      drawSelectedPointer(canvas, chartArea);
    }

    drawXAxis(canvas, chartArea);
    drawXLabels(canvas, chartArea);
    _drawCumulativeLabel(canvas, chartArea, itemWidth, cumulativeData, yRange);
    _drawDataMarkers(canvas, chartArea, itemWidth, cumulativeData, yRange);
  }

  List<List<_AreaBounds>> _calculateCumulativeData() {
    final result = <List<_AreaBounds>>[];
    final previousValues = <String, double>{}; // Track previous value per area

    for (int labelIndex = 0; labelIndex < data.labels.length; labelIndex++) {
      final areaBounds = <_AreaBounds>[];
      double positiveStack = 0.0;
      double negativeStack = 0.0;

      for (final area in data.areas) {
        // Try to find point for this index
        final pointOrNull = area.points.where((p) => p.labelIndex == labelIndex).firstOrNull;

        final double value;
        if (pointOrNull != null) {
          value = pointOrNull.value;
          previousValues[area.label] = value; // Update previous value
        } else {
          // Missing data - use configured behavior
          if (missingDataBehavior == MissingDataBehavior.previousValue && previousValues.containsKey(area.label)) {
            value = previousValues[area.label]!;
          } else {
            value = 0.0;
          }
        }

        double bottom, top;

        if (value >= 0) {
          bottom = positiveStack;
          top = positiveStack + value;
          positiveStack = top;
        } else {
          top = negativeStack;
          bottom = negativeStack + value;
          negativeStack = bottom;
        }

        areaBounds.add(_AreaBounds(bottom: bottom, top: top));
      }
      result.add(areaBounds);
    }

    return result;
  }

  ({double min, double max}) _calculateVisibleYRange(List<List<_AreaBounds>> cumulativeData) {
    final paddingWidth = (visibleLabels - 1) * itemWidth;
    final firstVisibleIndex = ((scrollOffset - paddingWidth) / itemWidth)
        .floor()
        .clamp(0, data.labels.length - 1);
    final lastVisibleIndex = (firstVisibleIndex + visibleLabels - 1)
        .clamp(0, data.labels.length - 1);

    double minValue = 0.0;
    double maxValue = 0.0;

    for (int i = firstVisibleIndex; i <= lastVisibleIndex; i++) {
      if (i >= cumulativeData.length) break;

      for (final areaBound in cumulativeData[i]) {
        if (areaBound.bottom < minValue) minValue = areaBound.bottom;
        if (areaBound.top > maxValue) maxValue = areaBound.top;
      }
    }

    final padding = (maxValue - minValue) * 0.1;
    return (
      min: minValue >= 0 ? 0.0 : minValue - padding,
      max: maxValue + padding,
    );
  }

  void _drawAreas(
    Canvas canvas,
    Rect chartArea,
    double itemWidth,
    List<List<_AreaBounds>> cumulativeData,
    ({double min, double max}) yRange,
  ) {
    final yScale = chartArea.height / (yRange.max - yRange.min);

    for (int areaIndex = 0; areaIndex < data.areas.length; areaIndex++) {
      final area = data.areas[areaIndex];
      final path = Path();

      // Draw top line (left to right)
      for (int labelIndex = 0; labelIndex < data.labels.length; labelIndex++) {
        final x = chartArea.left + (labelIndex * itemWidth) + (itemWidth / 2);
        final bounds = cumulativeData[labelIndex][areaIndex];
        final y = chartArea.top + ((yRange.max - bounds.top) * yScale);

        if (labelIndex == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Draw bottom line (right to left)
      for (int labelIndex = data.labels.length - 1; labelIndex >= 0; labelIndex--) {
        final x = chartArea.left + (labelIndex * itemWidth) + (itemWidth / 2);
        final bounds = cumulativeData[labelIndex][areaIndex];
        final y = chartArea.top + ((yRange.max - bounds.bottom) * yScale);
        path.lineTo(x, y);
      }

      path.close();

      final paint = Paint()
        ..color = area.color
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  void _drawCumulativeLabel(
    Canvas canvas,
    Rect chartArea,
    double itemWidth,
    List<List<_AreaBounds>> cumulativeData,
    ({double min, double max}) yRange,
  ) {
    if (cumulativeData.isEmpty || cumulativeLabelStyle == null) return;

    final yScale = chartArea.height / (yRange.max - yRange.min);
    final style = cumulativeLabelStyle!;
    final previousValues = <String, double>{}; // Track previous values per area

    for (int labelIndex = 0; labelIndex < data.labels.length; labelIndex++) {
      // Calculate NET value (sum of all positive and negative values)
      double netValue = 0.0;
      double maxPositiveTop = 0.0;

      for (final area in data.areas) {
        final pointOrNull = area.points.where((p) => p.labelIndex == labelIndex).firstOrNull;

        final double value;
        if (pointOrNull != null) {
          value = pointOrNull.value;
          previousValues[area.label] = value;
        } else {
          // Missing data - use configured behavior
          if (missingDataBehavior == MissingDataBehavior.previousValue && previousValues.containsKey(area.label)) {
            value = previousValues[area.label]!;
          } else {
            value = 0.0;
          }
        }
        netValue += value;
      }

      // Find the highest positive point to display label
      for (final bounds in cumulativeData[labelIndex]) {
        if (bounds.top > maxPositiveTop) {
          maxPositiveTop = bounds.top;
        }
      }

      final x = chartArea.left + (labelIndex * itemWidth) + (itemWidth / 2);
      final y = chartArea.top + ((yRange.max - maxPositiveTop) * yScale);

      final textSpan = TextSpan(
        text: netValue.toStringAsFixed(0),
        style: TextStyle(
          color: style.textColor,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Draw rounded rectangle container
      final containerWidth = textPainter.width + style.padding.horizontal;
      final containerHeight = textPainter.height + style.padding.vertical;
      final containerRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + style.offsetX, y + style.offsetY),
          width: containerWidth,
          height: containerHeight,
        ),
        Radius.circular(style.cornerRadius),
      );

      final containerPaint = Paint()
        ..color = style.containerColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(containerRect, containerPaint);

      // Draw text on top of container
      textPainter.paint(
        canvas,
        Offset(
          x + style.offsetX - textPainter.width / 2,
          y + style.offsetY - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawDataMarkers(
    Canvas canvas,
    Rect chartArea,
    double itemWidth,
    List<List<_AreaBounds>> cumulativeData,
    ({double min, double max}) yRange,
  ) {
    if (cumulativeData.isEmpty || dataMarkerStyle == null) return;

    final yScale = chartArea.height / (yRange.max - yRange.min);
    final style = dataMarkerStyle!;

    for (int labelIndex = 0; labelIndex < data.labels.length; labelIndex++) {
      // Find the highest positive point to position marker
      double maxPositiveTop = 0.0;
      for (final bounds in cumulativeData[labelIndex]) {
        if (bounds.top > maxPositiveTop) {
          maxPositiveTop = bounds.top;
        }
      }

      final x = chartArea.left + (labelIndex * itemWidth) + (itemWidth / 2);
      final y = chartArea.top + ((yRange.max - maxPositiveTop) * yScale);

      switch (style.type) {
        case DataMarkerType.circle:
          drawCircleMarker(canvas, x, y, style);
          break;
        case DataMarkerType.rectangle:
          drawRectangleMarker(canvas, x, y, style);
          break;
        case DataMarkerType.diamond:
          drawDiamondMarker(canvas, x, y, style);
          break;
        case DataMarkerType.triangle:
          drawTriangleMarker(canvas, x, y, style);
          break;
        case DataMarkerType.invertedTriangle:
          drawInvertedTriangleMarker(canvas, x, y, style);
          break;
        case DataMarkerType.pentagon:
          drawPentagonMarker(canvas, x, y, style);
          break;
        case DataMarkerType.verticalLine:
          drawVerticalLineMarker(canvas, x, y, style);
          break;
        case DataMarkerType.horizontalLine:
          drawHorizontalLineMarker(canvas, x, y, style);
          break;
        case DataMarkerType.image:
          drawCircleMarker(canvas, x, y, style);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(StackedAreaChartPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.data != data ||
        oldDelegate.visibleLabels != visibleLabels ||
        oldDelegate.itemWidth != itemWidth ||
        oldDelegate.selectedPointerStyle != selectedPointerStyle ||
        oldDelegate.gridLinesStyle != gridLinesStyle ||
        oldDelegate.cumulativeLabelStyle != cumulativeLabelStyle ||
        oldDelegate.dataMarkerStyle != dataMarkerStyle ||
        oldDelegate.missingDataBehavior != missingDataBehavior ||
        oldDelegate.animatedYMin != animatedYMin ||
        oldDelegate.animatedYMax != animatedYMax;
  }
}

class _AreaBounds {
  final double bottom;
  final double top;

  _AreaBounds({required this.bottom, required this.top});
}
