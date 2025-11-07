import 'package:flutter/material.dart';

/// Function that transforms a numeric value to a string for display in labels
typedef LabelTransformer = String Function(double value);

/// Default label transformer that formats values as integers
String defaultLabelTransformer(double value) => value.toStringAsFixed(0);

/// Behavior for handling missing data points
enum MissingDataBehavior {
  /// Use 0 for missing data points
  zero,

  /// Use previous value for missing data points (forward fill)
  previousValue,
}

/// Data model for a single area point in the stacked area chart
class AreaDataPoint {
  final int labelIndex;
  final double value;

  AreaDataPoint({
    required this.labelIndex,
    required this.value,
  });
}

/// Data model for an area in the stacked area chart
class AreaData {
  final String label;
  final Color color;
  final List<AreaDataPoint> points;

  AreaData({
    required this.label,
    required this.color,
    required this.points,
  });
}

/// X axis index to label mapping
class ChartLabel {
  final String label;
  final int index;

  ChartLabel({
    required this.label,
    required this.index,
  });
}

/// Input data model for the stacked area chart widget
class StackedAreaChartData {
  final List<ChartLabel> labels;
  final List<AreaData> areas;

  StackedAreaChartData({
    required this.labels,
    required this.areas,
  });
}

/// Data model for a single line point in the line chart
class LineDataPoint {
  final int labelIndex;
  final double value;

  LineDataPoint({
    required this.labelIndex,
    required this.value,
  });
}

/// Data model for a line in the line chart
class LineData {
  final String label;
  final Color color;
  final List<LineDataPoint> points;
  final double strokeWidth;

  LineData({
    required this.label,
    required this.color,
    required this.points,
    this.strokeWidth = 2.0,
  });
}

/// Input data model for the line chart widget
class LineChartData {
  final List<ChartLabel> labels;
  final List<LineData> lines;

  LineChartData({
    required this.labels,
    required this.lines,
  });
}
