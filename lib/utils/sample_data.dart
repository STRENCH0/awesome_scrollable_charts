import 'package:flutter/material.dart';
import '../models/chart_data.dart';

StackedAreaChartData getSampleChartData() {
  final labels = [
    ChartLabel(label: 'Jan', index: 0),
    ChartLabel(label: 'Feb', index: 1),
    ChartLabel(label: 'Mar', index: 2),
    ChartLabel(label: 'Apr', index: 3),
    ChartLabel(label: 'May', index: 4),
    ChartLabel(label: 'Jun', index: 5),
    ChartLabel(label: 'Jul', index: 6),
    ChartLabel(label: 'Aug', index: 7),
    ChartLabel(label: 'Sep', index: 8),
    ChartLabel(label: 'Oct', index: 9),
    ChartLabel(label: 'Nov', index: 10),
    ChartLabel(label: 'Dec', index: 11),
  ];

  final areas = [
    AreaData(
      label: 'Savings',
      color: Colors.green.shade300.withValues(alpha: 0.8),
      points: [
        AreaDataPoint(labelIndex: 0, value: 5000),
        AreaDataPoint(labelIndex: 1, value: 5500),
        AreaDataPoint(labelIndex: 2, value: 6000),
        AreaDataPoint(labelIndex: 3, value: 6500),
        AreaDataPoint(labelIndex: 4, value: 7000),
        AreaDataPoint(labelIndex: 5, value: 7500),
        AreaDataPoint(labelIndex: 6, value: 8000),
        AreaDataPoint(labelIndex: 7, value: 8500),
        AreaDataPoint(labelIndex: 8, value: 9000),
        AreaDataPoint(labelIndex: 9, value: 9500),
        AreaDataPoint(labelIndex: 10, value: 10000),
        AreaDataPoint(labelIndex: 11, value: 10500),
      ],
    ),
    AreaData(
      label: 'Investments',
      color: Colors.blue.shade300.withValues(alpha: 0.8),
      points: [
        AreaDataPoint(labelIndex: 0, value: 3000),
        AreaDataPoint(labelIndex: 1, value: 3200),
        AreaDataPoint(labelIndex: 2, value: 3500),
        AreaDataPoint(labelIndex: 3, value: 3800),
        AreaDataPoint(labelIndex: 4, value: 4000),
        AreaDataPoint(labelIndex: 5, value: 4300),
        AreaDataPoint(labelIndex: 6, value: 4500),
        AreaDataPoint(labelIndex: 7, value: 4800),
        // AreaDataPoint(labelIndex: 8, value: 5000),
        AreaDataPoint(labelIndex: 9, value: 5300),
        AreaDataPoint(labelIndex: 10, value: 5500),
        AreaDataPoint(labelIndex: 11, value: 5800),
      ],
    ),
    AreaData(
      label: 'Real Estate',
      color: Colors.orange.shade300.withValues(alpha: 0.8),
      points: [
        AreaDataPoint(labelIndex: 0, value: 2000),
        AreaDataPoint(labelIndex: 1, value: 2100),
        AreaDataPoint(labelIndex: 2, value: 2200),
        AreaDataPoint(labelIndex: 3, value: 2300),
        AreaDataPoint(labelIndex: 4, value: 2400),
        AreaDataPoint(labelIndex: 5, value: 2500),
        AreaDataPoint(labelIndex: 6, value: 2600),
        AreaDataPoint(labelIndex: 7, value: 2700),
        AreaDataPoint(labelIndex: 8, value: 2800),
        AreaDataPoint(labelIndex: 9, value: 2900),
        AreaDataPoint(labelIndex: 10, value: 3000),
        AreaDataPoint(labelIndex: 11, value: 3100),
      ],
    ),
    AreaData(
      label: 'Debt',
      color: Colors.red.shade300,
      points: [
        AreaDataPoint(labelIndex: 0, value: -1000),
        AreaDataPoint(labelIndex: 1, value: -5000),
        AreaDataPoint(labelIndex: 2, value: -900),
        AreaDataPoint(labelIndex: 3, value: -600),
        AreaDataPoint(labelIndex: 4, value: -300),
        AreaDataPoint(labelIndex: 5, value: -100),
        AreaDataPoint(labelIndex: 6, value: 0),
        AreaDataPoint(labelIndex: 7, value: 200),
        AreaDataPoint(labelIndex: 8, value: 400),
        AreaDataPoint(labelIndex: 9, value: 600),
        AreaDataPoint(labelIndex: 10, value: 0),
        AreaDataPoint(labelIndex: 11, value: -8000),
      ],
    ),
  ];

  return StackedAreaChartData(
    labels: labels,
    areas: areas,
  );
}
