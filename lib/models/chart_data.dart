import 'package:flutter/material.dart';

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
