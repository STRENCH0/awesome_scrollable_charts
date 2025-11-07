import 'dart:async';
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
import 'month_snap_scroll_physics.dart';

typedef OnVisibleRangeChanged = void Function(List<int> visibleIndices);
typedef OnSelectedChanged = void Function(int selectedIndex);

class StackedAreaChart extends StatefulWidget {
  final StackedAreaChartData data;
  final int visibleLabels;
  final SelectedPointerStyle? selectedPointerStyle;
  final GridLinesStyle? gridLinesStyle;
  final CumulativeLabelStyle? cumulativeLabelStyle;
  final DataMarkerStyle? dataMarkerStyle;
  final ZeroLineStyle zeroLineStyle;
  final XAxisStyle xAxisStyle;
  final XAxisLabelStyle xAxisLabelStyle;
  final MissingDataBehavior missingDataBehavior;
  final YAxisAnimationConfig yAxisAnimationConfig;
  final ScrollPhysicsConfig scrollPhysicsConfig;
  final OnVisibleRangeChanged? onVisibleRangeChanged;
  final OnSelectedChanged? onSelectedChanged;

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
  });

  @override
  State<StackedAreaChart> createState() => _StackedAreaChartState();
}

class _StackedAreaChartState extends State<StackedAreaChart>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  late AnimationController _yRangeAnimationController;
  late Animation<double> _yMinAnimation;
  late Animation<double> _yMaxAnimation;

  double _currentYMin = 0.0;
  double _currentYMax = 0.0;
  double _targetYMin = 0.0;
  double _targetYMax = 0.0;

  int _lastFirstVisibleIndex = -1;
  int _lastLastVisibleIndex = -1;
  int _lastSelectedIndex = -1;

  Timer? _scrollDebounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _yRangeAnimationController = AnimationController(
      duration: widget.yAxisAnimationConfig.duration,
      vsync: this,
    );

    _yMinAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _yRangeAnimationController,
        curve: widget.yAxisAnimationConfig.curve,
      ),
    );

    _yMaxAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _yRangeAnimationController,
        curve: widget.yAxisAnimationConfig.curve,
      ),
    );

    _yRangeAnimationController.addListener(() {
      setState(() {
        _currentYMin = _yMinAnimation.value;
        _currentYMax = _yMaxAnimation.value;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        final itemWidth = screenWidth / widget.visibleLabels;
        final initialOffset = (widget.visibleLabels - 1) * itemWidth;
        _scrollController.jumpTo(initialOffset);
        _updateYRange();
      }
    });
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _yRangeAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });

    // Cancel existing timer
    _scrollDebounceTimer?.cancel();

    // Start new timer - update Y range only when scrolling stops
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 30), () {
      _updateYRange();
    });
  }

  void _updateYRange() {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / widget.visibleLabels;
    final paddingWidth = (widget.visibleLabels - 1) * itemWidth;

    final rawFirstIndex = ((_scrollOffset - paddingWidth) / itemWidth).floor();
    final firstVisibleIndex = rawFirstIndex.clamp(0, widget.data.labels.length - 1);
    var lastVisibleIndex = (firstVisibleIndex + widget.visibleLabels - 1)
        .clamp(0, widget.data.labels.length - 1);

    // Symmetric boundary handling at start
    if (rawFirstIndex < 0) {
      final actualVisibleCount = widget.visibleLabels + rawFirstIndex;
      lastVisibleIndex = (actualVisibleCount - 1).clamp(0, widget.data.labels.length - 1);
    }

    final selectedIndex = _calculateSelectedIndex();

    // Check what changed
    final rangeChanged = firstVisibleIndex != _lastFirstVisibleIndex ||
                         lastVisibleIndex != _lastLastVisibleIndex;
    final selectedChanged = selectedIndex != _lastSelectedIndex;

    // Return early only if nothing changed
    if (!rangeChanged && !selectedChanged) {
      return;
    }

    // Update state and call callbacks for visible range change
    if (rangeChanged) {
      _lastFirstVisibleIndex = firstVisibleIndex;
      _lastLastVisibleIndex = lastVisibleIndex;

      if (widget.onVisibleRangeChanged != null) {
        final visibleIndices = List<int>.generate(
          lastVisibleIndex - firstVisibleIndex + 1,
          (i) => firstVisibleIndex + i,
        );
        widget.onVisibleRangeChanged!(visibleIndices);
      }
    }

    // Update state and call callback for selected index change
    if (selectedChanged) {
      _lastSelectedIndex = selectedIndex;
      widget.onSelectedChanged?.call(selectedIndex);
    }

    // Update Y range only if visible range changed
    if (!rangeChanged) {
      return;
    }

    final newYRange = _calculateTargetYRange(firstVisibleIndex, lastVisibleIndex);

    if ((newYRange.min - _targetYMin).abs() > 0.01 ||
        (newYRange.max - _targetYMax).abs() > 0.01) {
      _targetYMin = newYRange.min;
      _targetYMax = newYRange.max;

      // If duration is zero, update immediately without animation
      if (widget.yAxisAnimationConfig.duration == Duration.zero) {
        setState(() {
          _currentYMin = _targetYMin;
          _currentYMax = _targetYMax;
        });
        return;
      }

      _yMinAnimation = Tween<double>(
        begin: _currentYMin,
        end: _targetYMin,
      ).animate(
        CurvedAnimation(
          parent: _yRangeAnimationController,
          curve: widget.yAxisAnimationConfig.curve,
        ),
      );

      _yMaxAnimation = Tween<double>(
        begin: _currentYMax,
        end: _targetYMax,
      ).animate(
        CurvedAnimation(
          parent: _yRangeAnimationController,
          curve: widget.yAxisAnimationConfig.curve,
        ),
      );

      _yRangeAnimationController.forward(from: 0.0);
    }
  }

  int _calculateSelectedIndex() {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / widget.visibleLabels;
    final paddingWidth = (widget.visibleLabels - 1) * itemWidth;

    final double centerOffset;
    if (widget.visibleLabels % 2 == 0) {
      centerOffset = (widget.visibleLabels - 2) / 2.0;
    } else {
      centerOffset = (widget.visibleLabels - 1) / 2.0;
    }

    return ((_scrollOffset - paddingWidth) / itemWidth + centerOffset)
        .round()
        .clamp(0, widget.data.labels.length - 1);
  }

  ({double min, double max}) _calculateTargetYRange(int firstVisibleIndex, int lastVisibleIndex) {
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

    final minScrollBound = max(0.0, paddingWidth - itemWidth);
    final maxScrollBound = paddingWidth + ((totalLabels - 2) * itemWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return SingleChildScrollView(
          controller: _scrollController,
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
              scrollOffset: _scrollOffset,
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
              animatedYMin: _currentYMin,
              animatedYMax: _currentYMax,
            ),
          ),
        );
      },
    );
  }
}

class StackedAreaChartPainter extends CustomPainter {
  final StackedAreaChartData data;
  final int visibleLabels;
  final double scrollOffset;
  final double totalWidth;
  final double itemWidth;
  final SelectedPointerStyle? selectedPointerStyle;
  final GridLinesStyle? gridLinesStyle;
  final CumulativeLabelStyle? cumulativeLabelStyle;
  final DataMarkerStyle? dataMarkerStyle;
  final ZeroLineStyle zeroLineStyle;
  final XAxisStyle xAxisStyle;
  final XAxisLabelStyle xAxisLabelStyle;
  final MissingDataBehavior missingDataBehavior;
  final double animatedYMin;
  final double animatedYMax;

  StackedAreaChartPainter({
    required this.data,
    required this.visibleLabels,
    required this.scrollOffset,
    required this.totalWidth,
    required this.itemWidth,
    this.selectedPointerStyle,
    this.gridLinesStyle,
    this.cumulativeLabelStyle,
    this.dataMarkerStyle,
    required this.zeroLineStyle,
    required this.xAxisStyle,
    required this.xAxisLabelStyle,
    required this.missingDataBehavior,
    required this.animatedYMin,
    required this.animatedYMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.areas.isEmpty || data.labels.isEmpty) return;

    final paddingWidth = (visibleLabels - 1) * itemWidth;
    final chartArea = Rect.fromLTWH(paddingWidth, 40, data.labels.length * itemWidth, size.height - 80);

    // Calculate cumulative values and Y-axis range
    final cumulativeData = _calculateCumulativeData();
    final yRange = (animatedYMin != 0.0 || animatedYMax != 0.0)
        ? (min: animatedYMin, max: animatedYMax)
        : _calculateVisibleYRange(cumulativeData);

    // Draw grid lines
    _drawGridLines(canvas, chartArea);

    // Draw areas
    _drawAreas(canvas, chartArea, itemWidth, cumulativeData, yRange);

    // Draw zero line
    _drawZeroLine(canvas, chartArea, yRange);

    // Draw selected pointer
    if (selectedPointerStyle != null) {
      _drawSelectedPointer(canvas, chartArea, itemWidth);
    }

    // Draw X-axis
    _drawXAxis(canvas, chartArea, itemWidth);

    // Draw X-axis labels
    _drawXLabels(canvas, chartArea, itemWidth);

    // Draw cumulative value label
    _drawCumulativeLabel(canvas, chartArea, itemWidth, cumulativeData, yRange);

    // Draw data markers
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

  void _drawGridLines(Canvas canvas, Rect chartArea) {
    if (gridLinesStyle == null) return;

    final paint = Paint()
      ..color = gridLinesStyle!.color
      ..strokeWidth = gridLinesStyle!.width
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < data.labels.length; i++) {
      final x = chartArea.left + (i * itemWidth) + (itemWidth / 2);

      if (gridLinesStyle!.isDashed) {
        _drawDashedVerticalLine(
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

  void _drawZeroLine(
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
      _drawDashedHorizontalLine(
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

  void _drawSelectedPointer(Canvas canvas, Rect chartArea, double itemWidth) {
    final paddingWidth = (visibleLabels - 1) * itemWidth;

    final double centerOffset;
    if (visibleLabels % 2 == 0) {
      // Even: n/2
      centerOffset = (visibleLabels - 2) / 2.0;
    } else {
      // Odd: (n+1)/2
      centerOffset = (visibleLabels - 1) / 2.0;
    }

    final selectedIndex = ((scrollOffset - paddingWidth) / itemWidth + centerOffset)
        .round()
        .clamp(0, data.labels.length - 1);

    final x = chartArea.left + (selectedIndex * itemWidth) + (itemWidth / 2);

    final paint = Paint()
      ..color = selectedPointerStyle!.color
      ..strokeWidth = selectedPointerStyle!.width
      ..style = PaintingStyle.stroke;

    if (selectedPointerStyle!.isDashed) {
      _drawDashedVerticalLine(
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

  void _drawDashedVerticalLine(
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

  void _drawDashedHorizontalLine(
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

  void _drawXAxis(Canvas canvas, Rect chartArea, double itemWidth) {
    if (!xAxisStyle.enabled) return;

    final paint = Paint()
      ..color = xAxisStyle.color
      ..strokeWidth = xAxisStyle.width
      ..style = PaintingStyle.stroke;

    final startPoint = Offset(chartArea.left, chartArea.bottom);
    final endPoint = Offset(chartArea.right, chartArea.bottom);

    if (xAxisStyle.isDashed) {
      _drawDashedHorizontalLine(
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

  void _drawXLabels(Canvas canvas, Rect chartArea, double itemWidth) {
    if (!xAxisLabelStyle.enabled) return;

    for (int i = 0; i < data.labels.length; i++) {
      final label = data.labels[i];
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

      // Draw marker based on type
      switch (style.type) {
        case DataMarkerType.circle:
          _drawCircleMarker(canvas, x, y, style);
          break;
        case DataMarkerType.rectangle:
          _drawRectangleMarker(canvas, x, y, style);
          break;
        case DataMarkerType.diamond:
          _drawDiamondMarker(canvas, x, y, style);
          break;
        case DataMarkerType.triangle:
          _drawTriangleMarker(canvas, x, y, style);
          break;
        case DataMarkerType.invertedTriangle:
          _drawInvertedTriangleMarker(canvas, x, y, style);
          break;
        case DataMarkerType.pentagon:
          _drawPentagonMarker(canvas, x, y, style);
          break;
        case DataMarkerType.verticalLine:
          _drawVerticalLineMarker(canvas, x, y, style);
          break;
        case DataMarkerType.horizontalLine:
          _drawHorizontalLineMarker(canvas, x, y, style);
          break;
        case DataMarkerType.image:
          // TODO: Implement image marker
          _drawCircleMarker(canvas, x, y, style); // Fallback to circle
          break;
      }
    }
  }

  void _drawCircleMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
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

  void _drawRectangleMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
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

  void _drawDiamondMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
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

  void _drawTriangleMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
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

  void _drawInvertedTriangleMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
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

  void _drawPentagonMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
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

  void _drawVerticalLineMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
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

  void _drawHorizontalLineMarker(Canvas canvas, double x, double y, DataMarkerStyle style) {
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
