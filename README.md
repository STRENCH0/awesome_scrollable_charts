# Scrollable Charts

Beautiful, animated, and highly customizable scrollable charts for Flutter. Create stunning line charts and stacked area charts with smooth scrolling, animations, and extensive styling options.

<img src="https://raw.githubusercontent.com/strench0/awesome_scrollable_charts/main/example/images/example.gif" alt="Example" width="400" />

## Features

✨ **Two Chart Types**
- **Line Chart**: Perfect for displaying trends and data points over time
- **Stacked Area Chart**: Ideal for showing cumulative values and part-to-whole relationships

📱 **Smooth Scrolling**
- Horizontal scrolling with snap-to-position physics
- Configurable visible data points
- Smooth animations when scrolling

🎨 **Highly Customizable**
- Grid lines with dashed/solid styles
- Multiple data marker shapes (circle, square, diamond, triangle, pentagon, etc.)
- Custom colors, fonts, and styling for all elements
- X-axis and zero-line customization
- Data labels with customizable positioning

⚡ **Animated**
- Smooth Y-axis range animations
- Configurable animation curves and durations
- Real-time chart updates

🔧 **Flexible Data Handling**
- Support for missing data points
- Multiple lines/areas on a single chart
- Custom label formatting
- Initial display position control
- Callbacks for visible range and selection changes

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  awesome_scrollable_charts: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Line Chart

```dart
import 'package:flutter/material.dart';
import 'package:awesome_scrollable_charts/awesome_scrollable_charts.dart';

class MyLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
      data: LineChartData(
        labels: [
          ChartLabel(label: 'Jan', index: 0),
          ChartLabel(label: 'Feb', index: 1),
          ChartLabel(label: 'Mar', index: 2),
          ChartLabel(label: 'Apr', index: 3),
          ChartLabel(label: 'May', index: 4),
        ],
        lines: [
          LineData(
            label: 'Revenue',
            color: Colors.blue,
            strokeWidth: 2.0,
            points: [
              LineDataPoint(labelIndex: 0, value: 1000),
              LineDataPoint(labelIndex: 1, value: 1500),
              LineDataPoint(labelIndex: 2, value: 1200),
              LineDataPoint(labelIndex: 3, value: 1800),
              LineDataPoint(labelIndex: 4, value: 2200),
            ],
          ),
        ],
      ),
      visibleLabels: 3,
      smooth: true,
      gridLinesStyle: GridLinesStyle(
        color: Colors.grey.withOpacity(0.3),
        isDashed: true,
      ),
      dataMarkerStyle: DataMarkerStyle(
        type: DataMarkerType.circle,
        width: 8,
        height: 8,
      ),
    );
  }
}
```

### Stacked Area Chart

```dart
import 'package:flutter/material.dart';
import 'package:awesome_scrollable_charts/awesome_scrollable_charts.dart';

class MyStackedAreaChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StackedAreaChart(
      data: StackedAreaChartData(
        labels: [
          ChartLabel(label: 'Q1', index: 0),
          ChartLabel(label: 'Q2', index: 1),
          ChartLabel(label: 'Q3', index: 2),
          ChartLabel(label: 'Q4', index: 3),
        ],
        areas: [
          AreaData(
            label: 'Product A',
            color: Colors.blue.withOpacity(0.7),
            points: [
              AreaDataPoint(labelIndex: 0, value: 500),
              AreaDataPoint(labelIndex: 1, value: 700),
              AreaDataPoint(labelIndex: 2, value: 600),
              AreaDataPoint(labelIndex: 3, value: 900),
            ],
          ),
          AreaData(
            label: 'Product B',
            color: Colors.green.withOpacity(0.7),
            points: [
              AreaDataPoint(labelIndex: 0, value: 300),
              AreaDataPoint(labelIndex: 1, value: 400),
              AreaDataPoint(labelIndex: 2, value: 500),
              AreaDataPoint(labelIndex: 3, value: 450),
            ],
          ),
        ],
      ),
      visibleLabels: 3,
      cumulativeLabelStyle: CumulativeLabelStyle(
        enabled: true,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
```

## Customization Options

### Chart Styling

```dart
LineChart(
  data: yourData,
  visibleLabels: 3,

  // Grid lines
  gridLinesStyle: GridLinesStyle(
    color: Colors.grey,
    width: 1.0,
    isDashed: true,
    dashLength: 5.0,
    dashGap: 3.0,
  ),

  // Selected pointer
  selectedPointerStyle: SelectedPointerStyle(
    color: Colors.red,
    width: 2.0,
    isDashed: true,
  ),

  // Zero line
  zeroLineStyle: ZeroLineStyle(
    enabled: true,
    color: Colors.black,
    width: 1.5,
  ),

  // X-axis
  xAxisStyle: XAxisStyle(
    enabled: true,
    color: Colors.black,
    width: 1.0,
  ),

  // X-axis labels
  xAxisLabelStyle: XAxisLabelStyle(
    enabled: true,
    color: Colors.black87,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    distanceFromAxis: 8.0,
  ),

  // Data markers
  dataMarkerStyle: DataMarkerStyle(
    type: DataMarkerType.circle,
    width: 10,
    height: 10,
    borderWidth: 2,
    borderColor: Colors.white,
  ),
);
```

### Animation Configuration

```dart
LineChart(
  data: yourData,

  // Y-axis animation
  yAxisAnimationConfig: YAxisAnimationConfig.smooth,
  // Or customize:
  // yAxisAnimationConfig: YAxisAnimationConfig(
  //   duration: Duration(milliseconds: 300),
  //   curve: Curves.easeInOut,
  // ),

  // Scroll physics
  scrollPhysicsConfig: ScrollPhysicsConfig.smooth,
  // Or customize:
  // scrollPhysicsConfig: ScrollPhysicsConfig(
  //   snapDuration: Duration(milliseconds: 150),
  //   snapCurve: Curves.easeOut,
  // ),
);
```

### Data Marker Types

The following marker types are available:
- `DataMarkerType.circle`
- `DataMarkerType.rectangle`
- `DataMarkerType.diamond`
- `DataMarkerType.triangle`
- `DataMarkerType.invertedTriangle`
- `DataMarkerType.pentagon`
- `DataMarkerType.verticalLine`
- `DataMarkerType.horizontalLine`

### Callbacks

```dart
LineChart(
  data: yourData,

  // Called when visible range changes
  onVisibleRangeChanged: (List<int> visibleIndices) {
    print('Visible indices: $visibleIndices');
  },

  // Called when selected index changes
  onSelectedChanged: (int selectedIndex) {
    print('Selected index: $selectedIndex');
  },
);
```

### Missing Data Handling

```dart
LineChart(
  data: yourData,

  // Choose how to handle missing data points
  missingDataBehavior: MissingDataBehavior.zero, // Default
  // Or:
  // missingDataBehavior: MissingDataBehavior.previousValue,
);
```

### Initial Display Position

Control which data point is displayed when the chart first loads:

```dart
LineChart(
  data: yourData,

  // Start at the first data point
  initialIndex: 0,

  // Or start at a specific index
  // initialIndex: 5,

  // If null (default), starts at the last data point
);

StackedAreaChart(
  data: yourData,

  // Start at the first data point
  initialIndex: 0,
);
```

The `initialIndex` parameter is available on both `LineChart` and `StackedAreaChart`. The value will be automatically clamped to valid indices (0 to labels.length - 1).

## Example

Check out the [example](example/) directory for a complete working example demonstrating all features.

To run the example:

```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you find this package useful, please consider giving it a ⭐ on [GitHub](https://github.com/strench0/awesome_scrollable_charts)!
