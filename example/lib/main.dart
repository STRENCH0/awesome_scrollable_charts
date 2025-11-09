import 'package:flutter/material.dart';
import 'package:awesome_scrollable_charts/awesome_scrollable_charts.dart';
import 'sample_data.dart';

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Stacked area chart', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                height: 350,
                width: double.infinity,
                child: StackedAreaChart(
                  data: getSampleChartData(),
                  visibleLabels: 3,
                  initialIndex: 11, // Start at the first data point
                  yAxisAnimationConfig: YAxisAnimationConfig(
                    curve: Curves.linear,
                  ),
                  scrollPhysicsConfig: ScrollPhysicsConfig.smooth,
                  onVisibleRangeChanged: (indices) => print('Visible: $indices'),
                  onSelectedChanged: (index) => print('Selected: $index'),
                  labelTransformer: (value) {
                    return '$value \$';
                  },
                  gridLinesStyle: GridLinesStyle(
                    isDashed: false
                  ),
                  dataMarkerStyle: DataMarkerStyle(),
                  missingDataBehavior: MissingDataBehavior.previousValue,
                  cumulativeLabelStyle: CumulativeLabelStyle(
                    cornerRadius: 8.0,
                    offsetY: -18,
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
                    enabled: false,
                  ),
                  xAxisLabelStyle: XAxisLabelStyle(
                    enabled: true,
                    textStyle: TextStyle(
                      color: Colors.black87,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                    distanceFromAxis: 10.0,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Linear chart', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                height: 350,
                width: double.infinity,
                child: LineChart(
                  data: getSampleLineChartData(),
                  visibleLabels: 3,
                  initialIndex: 0, // Start at the first data point
                  smooth: true,
                  yAxisAnimationConfig: YAxisAnimationConfig(
                    curve: Curves.linear,
                  ),
                  scrollPhysicsConfig: ScrollPhysicsConfig.fast,
                  onVisibleRangeChanged: (indices) => print('Line Visible: $indices'),
                  onSelectedChanged: (index) => print('Line Selected: $index'),
                  gridLinesStyle: GridLinesStyle(
                    isDashed: false
                  ),
                  dataMarkerStyle: DataMarkerStyle(
                    type: DataMarkerType.circle,
                    width: 8.0,
                    height: 8.0,
                    borderColor: Colors.white,
                    borderWidth: 2.0,
                  ),
                  missingDataBehavior: MissingDataBehavior.previousValue,
                  lineLabelStyle: LineLabelStyle(
                    overlapBehavior: LabelOverlapBehavior.adjust,
                    enabled: true,
                    useLineColorForText: false,
                    containerAlpha: 0.7,
                    cornerRadius: 6.0,
                    offsetY: -16,
                  ),
                  selectedPointerStyle: SelectedPointerStyle(
                    color: Colors.black,
                    width: 2.0,
                    isDashed: true,
                    dashLength: 8.0,
                    dashGap: 4.0,
                  ),
                  xAxisStyle: XAxisStyle(
                    enabled: false,
                  ),
                  zeroLineStyle: ZeroLineStyle(
                    isDashed: true,
                    dashLength: 8.0,
                    dashGap: 4.0,
                  ),
                  xAxisLabelStyle: XAxisLabelStyle(
                    enabled: true,
                    textStyle: TextStyle(
                      color: Colors.black87,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                    distanceFromAxis: 10.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
