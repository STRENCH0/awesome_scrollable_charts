import 'dart:async';
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
import 'month_snap_scroll_physics.dart';

typedef OnVisibleRangeChanged = void Function(List<int> visibleIndices);
typedef OnSelectedChanged = void Function(int selectedIndex);

class LineChart extends StatefulWidget {
  final LineChartData data;
  final int visibleLabels;
  final SelectedPointerStyle? selectedPointerStyle;
  final GridLinesStyle? gridLinesStyle;
  final LineLabelStyle? lineLabelStyle;
  final DataMarkerStyle? dataMarkerStyle;
  final ZeroLineStyle zeroLineStyle;
  final XAxisStyle xAxisStyle;
  final XAxisLabelStyle xAxisLabelStyle;
  final MissingDataBehavior missingDataBehavior;
  final YAxisAnimationConfig yAxisAnimationConfig;
  final ScrollPhysicsConfig scrollPhysicsConfig;
  final OnVisibleRangeChanged? onVisibleRangeChanged;
  final OnSelectedChanged? onSelectedChanged;
  final bool smooth;

  const LineChart({
    super.key,
    required this.data,
    this.visibleLabels = 3,
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

class _LineChartState extends State<LineChart>
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

    _scrollDebounceTimer?.cancel();

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

    if (rawFirstIndex < 0) {
      final actualVisibleCount = widget.visibleLabels + rawFirstIndex;
      lastVisibleIndex = (actualVisibleCount - 1).clamp(0, widget.data.labels.length - 1);
    }

    final selectedIndex = _calculateSelectedIndex();

    final rangeChanged = firstVisibleIndex != _lastFirstVisibleIndex ||
                         lastVisibleIndex != _lastLastVisibleIndex;
    final selectedChanged = selectedIndex != _lastSelectedIndex;

    if (!rangeChanged && !selectedChanged) {
      return;
    }

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

    if (selectedChanged) {
      _lastSelectedIndex = selectedIndex;
      widget.onSelectedChanged?.call(selectedIndex);
    }

    if (!rangeChanged) {
      return;
    }

    final newYRange = _calculateTargetYRange(firstVisibleIndex, lastVisibleIndex);

    if ((newYRange.min - _targetYMin).abs() > 0.01 ||
        (newYRange.max - _targetYMax).abs() > 0.01) {
      _targetYMin = newYRange.min;
      _targetYMax = newYRange.max;

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
            painter: LineChartPainter(
              data: widget.data,
              visibleLabels: widget.visibleLabels,
              scrollOffset: _scrollOffset,
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
              animatedYMin: _currentYMin,
              animatedYMax: _currentYMax,
              smooth: widget.smooth,
            ),
          ),
        );
      },
    );
  }
}

class LineChartPainter extends CustomPainter {
  final LineChartData data;
  final int visibleLabels;
  final double scrollOffset;
  final double totalWidth;
  final double itemWidth;
  final SelectedPointerStyle? selectedPointerStyle;
  final GridLinesStyle? gridLinesStyle;
  final LineLabelStyle? lineLabelStyle;
  final DataMarkerStyle? dataMarkerStyle;
  final ZeroLineStyle zeroLineStyle;
  final XAxisStyle xAxisStyle;
  final XAxisLabelStyle xAxisLabelStyle;
  final MissingDataBehavior missingDataBehavior;
  final double animatedYMin;
  final double animatedYMax;
  final bool smooth;

  LineChartPainter({
    required this.data,
    required this.visibleLabels,
    required this.scrollOffset,
    required this.totalWidth,
    required this.itemWidth,
    this.selectedPointerStyle,
    this.gridLinesStyle,
    this.lineLabelStyle,
    this.dataMarkerStyle,
    required this.zeroLineStyle,
    required this.xAxisStyle,
    required this.xAxisLabelStyle,
    required this.missingDataBehavior,
    required this.animatedYMin,
    required this.animatedYMax,
    required this.smooth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.lines.isEmpty || data.labels.isEmpty) return;

    final paddingWidth = (visibleLabels - 1) * itemWidth;
    final chartArea = Rect.fromLTWH(paddingWidth, 40, data.labels.length * itemWidth, size.height - 80);

    final lineData = _calculateLineData();
    final yRange = (animatedYMin != 0.0 || animatedYMax != 0.0)
        ? (min: animatedYMin, max: animatedYMax)
        : _calculateVisibleYRange(lineData);

    _drawGridLines(canvas, chartArea);
    _drawLines(canvas, chartArea, itemWidth, lineData, yRange);
    _drawZeroLine(canvas, chartArea, yRange);

    if (selectedPointerStyle != null) {
      _drawSelectedPointer(canvas, chartArea, itemWidth);
    }

    _drawXAxis(canvas, chartArea, itemWidth);
    _drawXLabels(canvas, chartArea, itemWidth);
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
      centerOffset = (visibleLabels - 2) / 2.0;
    } else {
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

        final textColor = style.useLineColor ? line.color : (style.textColor ?? Colors.black87);
        final containerColor = style.containerColor ?? line.color.withValues(alpha: 0.1);

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
            _drawCircleMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.rectangle:
            _drawRectangleMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.diamond:
            _drawDiamondMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.triangle:
            _drawTriangleMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.invertedTriangle:
            _drawInvertedTriangleMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.pentagon:
            _drawPentagonMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.verticalLine:
            _drawVerticalLineMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.horizontalLine:
            _drawHorizontalLineMarker(canvas, x, y, markerStyle);
            break;
          case DataMarkerType.image:
            _drawCircleMarker(canvas, x, y, markerStyle);
            break;
        }
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
