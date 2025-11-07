Goal is to make a widget

**Concept**
- Available as a reusable Flutter widget
- Should be accessed fab press on main screen
- Should be prefilled with sample data
- Stacked area chart
- Axis x - discreate labels
- Axis y - invisible floating point axis
- Each area has it's custom color and value
- Each area is shown based on initial order (top to bottom)
- On top of first area there must be a cumulative value label (sum of all areas values)
- If area value is below zero it's show below x axis (subtracting from cumulative value)
- Should have snappy scroll by x axis
- Y axis range should be calculated based on visible areas only
- Shown x axis labels: 3 by default, can be configured

**Input data structure**
```dart

// Data model for a single area point in the stacked area chart
class AreaDataPoint {
  final int labelIndex; // index for x axis position
  final double value; // area value
  final Color color; // area color

  AreaData({
    required this.labelIndex,
    required this.value,
    required this.color,
  });
}

// Data model for an area in the stacked area chart
class AreaData {
  final List<AreaDataPoint> points; // list of area data points

  AreaData({
    required this.label,
    required this.points,
  });
}

// X axis index to label mapping
class Labels {
  final String label; // label text
  final int index; // label index
  Labels({
    required this.label,
  });
}

// Input data model for the stacked area chart widget
class StackedAreaChartData {
  final List<Labels> labels; // labels for x axis
  final List<AreaData> areas; // list of area data

  StackedAreaChartData({
    required this.xLabels,
    required this.areas,
  });
}
```