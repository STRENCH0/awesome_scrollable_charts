import 'package:flutter/material.dart';
import 'package:net_worth_widget/models/chart_data.dart';
import 'package:net_worth_widget/models/data_marker_style.dart';
import 'package:net_worth_widget/models/grid_lines_style.dart';
import 'package:net_worth_widget/models/x_axis_label_style.dart';
import 'package:net_worth_widget/models/x_axis_style.dart';
import 'package:net_worth_widget/models/y_axis_animation_config.dart';
import 'package:net_worth_widget/models/zero_line_style.dart';
import 'models/cumulative_label_style.dart';
import 'models/scroll_physics_config.dart';
import 'models/selected_pointer_style.dart';
import 'widgets/stacked_area_chart.dart';
import 'utils/sample_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Net Worth Widget',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const MyHomePage(title: 'Net Worth Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Динамика активов', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              width: double.infinity,
              child: StackedAreaChart(
                data: getSampleChartData(),
                visibleLabels: 3,
                yAxisAnimationConfig: YAxisAnimationConfig(
                  curve: Curves.linear,
                ),
                scrollPhysicsConfig: ScrollPhysicsConfig.fast,
                onVisibleRangeChanged: (indices) => print('Visible: $indices'),
                onSelectedChanged: (index) => print('Selected: $index'),
                gridLinesStyle: GridLinesStyle(
                  isDashed: false
                ),
                dataMarkerStyle: DataMarkerStyle(),
                missingDataBehavior: MissingDataBehavior.previousValue,
                cumulativeLabelStyle: CumulativeLabelStyle(
                  cornerRadius: 8.0,
                  // offsetX: -20,
                  offsetY: -18
                ),
                selectedPointerStyle: SelectedPointerStyle(
                  color: Colors.black,
                  width: 2.0,
                  isDashed: true,
                  dashLength: 8.0,
                  dashGap: 4.0,
                ),
                zeroLineStyle: ZeroLineStyle(
                  enabled: true,
                  color: Colors.red.shade700,
                  width: 2.5,
                  isDashed: true,
                  dashLength: 6.0,
                  dashGap: 4.0,
                ),
                xAxisStyle: XAxisStyle(
                  enabled: true,
                  color: Colors.grey.shade600,
                  width: 1.5,
                  isDashed: false,
                ),
                xAxisLabelStyle: XAxisLabelStyle(
                  enabled: true,
                  color: Colors.black87,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  distanceFromAxis: 10.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
