import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/y_axis_animation_config.dart';

typedef OnVisibleRangeChanged = void Function(List<int> visibleIndices);
typedef OnSelectedChanged = void Function(int selectedIndex);

abstract class BaseScrollableChartState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  late ScrollController scrollController;
  double scrollOffset = 0.0;

  late AnimationController yRangeAnimationController;
  late Animation<double> yMinAnimation;
  late Animation<double> yMaxAnimation;

  double currentYMin = 0.0;
  double currentYMax = 0.0;
  double targetYMin = 0.0;
  double targetYMax = 0.0;

  int lastFirstVisibleIndex = -1;
  int lastLastVisibleIndex = -1;
  int lastSelectedIndex = -1;

  Timer? scrollDebounceTimer;
  double? _widgetWidth;

  int get labelsLength;
  int get visibleLabels;
  int? get initialIndex;
  YAxisAnimationConfig get yAxisAnimationConfig;
  OnVisibleRangeChanged? get onVisibleRangeChanged;
  OnSelectedChanged? get onSelectedChanged;

  ({double min, double max}) calculateTargetYRange(int firstVisibleIndex, int lastVisibleIndex);

  void updateWidgetWidth(double width) {
    _widgetWidth = width;
  }

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(onScroll);

    yRangeAnimationController = AnimationController(
      duration: yAxisAnimationConfig.duration,
      vsync: this,
    );

    yMinAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: yRangeAnimationController,
        curve: yAxisAnimationConfig.curve,
      ),
    );

    yMaxAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: yRangeAnimationController,
        curve: yAxisAnimationConfig.curve,
      ),
    );

    yRangeAnimationController.addListener(() {
      setState(() {
        currentYMin = yMinAnimation.value;
        currentYMax = yMaxAnimation.value;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Calculate initial offset based on initialIndex or default to last item
        final targetIndex = initialIndex?.clamp(0, labelsLength - 1) ?? (labelsLength - 1);
        final initialOffset = calculateScrollOffsetForIndex(targetIndex);

        scrollController.jumpTo(initialOffset);
        updateYRange();
      }
    });
  }

  @override
  void dispose() {
    scrollDebounceTimer?.cancel();
    scrollController.removeListener(onScroll);
    scrollController.dispose();
    yRangeAnimationController.dispose();
    super.dispose();
  }

  void onScroll() {
    setState(() {
      scrollOffset = scrollController.offset;
    });

    scrollDebounceTimer?.cancel();

    scrollDebounceTimer = Timer(const Duration(milliseconds: 30), () {
      updateYRange();
    });
  }

  double calculateCenterOffset() {
    if (visibleLabels % 2 == 0) {
      return (visibleLabels - 2) / 2.0;
    } else {
      return (visibleLabels - 1) / 2.0;
    }
  }

  double calculateScrollOffsetForIndex(int targetIndex) {
    final width = _widgetWidth ?? MediaQuery.of(context).size.width;
    final itemWidth = width / visibleLabels;
    final paddingWidth = (visibleLabels - 1) * itemWidth;
    final centerOffset = calculateCenterOffset();

    return paddingWidth + ((targetIndex - centerOffset) * itemWidth);
  }

  void updateYRange() {
    final width = _widgetWidth ?? MediaQuery.of(context).size.width;
    final itemWidth = width / visibleLabels;
    final paddingWidth = (visibleLabels - 1) * itemWidth;

    final rawFirstIndex = ((scrollOffset - paddingWidth) / itemWidth).floor();
    final firstVisibleIndex = rawFirstIndex.clamp(0, labelsLength - 1);
    var lastVisibleIndex = (firstVisibleIndex + visibleLabels - 1)
        .clamp(0, labelsLength - 1);

    if (rawFirstIndex < 0) {
      final actualVisibleCount = visibleLabels + rawFirstIndex;
      lastVisibleIndex = (actualVisibleCount - 1).clamp(0, labelsLength - 1);
    }

    final selectedIndex = calculateSelectedIndex();

    final rangeChanged = firstVisibleIndex != lastFirstVisibleIndex ||
                         lastVisibleIndex != lastLastVisibleIndex;
    final selectedChanged = selectedIndex != lastSelectedIndex;

    if (!rangeChanged && !selectedChanged) {
      return;
    }

    if (rangeChanged) {
      lastFirstVisibleIndex = firstVisibleIndex;
      lastLastVisibleIndex = lastVisibleIndex;

      if (onVisibleRangeChanged != null) {
        final visibleIndices = List<int>.generate(
          lastVisibleIndex - firstVisibleIndex + 1,
          (i) => firstVisibleIndex + i,
        );
        onVisibleRangeChanged!(visibleIndices);
      }
    }

    if (selectedChanged) {
      lastSelectedIndex = selectedIndex;
      onSelectedChanged?.call(selectedIndex);
    }

    if (!rangeChanged) {
      return;
    }

    final newYRange = calculateTargetYRange(firstVisibleIndex, lastVisibleIndex);

    if ((newYRange.min - targetYMin).abs() > 0.01 ||
        (newYRange.max - targetYMax).abs() > 0.01) {
      targetYMin = newYRange.min;
      targetYMax = newYRange.max;

      if (yAxisAnimationConfig.duration == Duration.zero) {
        setState(() {
          currentYMin = targetYMin;
          currentYMax = targetYMax;
        });
        return;
      }

      yMinAnimation = Tween<double>(
        begin: currentYMin,
        end: targetYMin,
      ).animate(
        CurvedAnimation(
          parent: yRangeAnimationController,
          curve: yAxisAnimationConfig.curve,
        ),
      );

      yMaxAnimation = Tween<double>(
        begin: currentYMax,
        end: targetYMax,
      ).animate(
        CurvedAnimation(
          parent: yRangeAnimationController,
          curve: yAxisAnimationConfig.curve,
        ),
      );

      yRangeAnimationController.forward(from: 0.0);
    }
  }

  int calculateSelectedIndex() {
    final width = _widgetWidth ?? MediaQuery.of(context).size.width;
    final itemWidth = width / visibleLabels;
    final paddingWidth = (visibleLabels - 1) * itemWidth;
    final centerOffset = calculateCenterOffset();

    return ((scrollOffset - paddingWidth) / itemWidth + centerOffset)
        .round()
        .clamp(0, labelsLength - 1);
  }
}
