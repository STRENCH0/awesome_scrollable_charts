import 'package:flutter/material.dart';
import '../models/scroll_physics_config.dart';

class MonthSnapScrollPhysics extends ScrollPhysics {
  final double itemWidth;
  final ScrollPhysicsConfig scrollPhysicsConfig;
  final double? minScrollBound;
  final double? maxScrollBound;

  const MonthSnapScrollPhysics({
    required this.itemWidth,
    this.scrollPhysicsConfig = ScrollPhysicsConfig.smooth,
    this.minScrollBound,
    this.maxScrollBound,
    super.parent,
  });

  @override
  MonthSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MonthSnapScrollPhysics(
      itemWidth: itemWidth,
      scrollPhysicsConfig: scrollPhysicsConfig,
      minScrollBound: minScrollBound,
      maxScrollBound: maxScrollBound,
      parent: buildParent(ancestor),
    );
  }

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    final page = position.pixels / itemWidth;
    final minExtent = minScrollBound ?? position.minScrollExtent;
    final maxExtent = maxScrollBound ?? position.maxScrollExtent;

    if (velocity < -tolerance.velocity) {
      return (page.floor() * itemWidth).clamp(minExtent, maxExtent);
    } else if (velocity > tolerance.velocity) {
      return (page.ceil() * itemWidth).clamp(minExtent, maxExtent);
    }

    return (page.round() * itemWidth).clamp(minExtent, maxExtent);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final minExtent = minScrollBound ?? position.minScrollExtent;
    final maxExtent = maxScrollBound ?? position.maxScrollExtent;

    if ((velocity <= 0.0 && position.pixels <= minExtent) ||
        (velocity >= 0.0 && position.pixels >= maxExtent)) {
      return null;
    }

    final tolerance = toleranceFor(position);
    final target = _getTargetPixels(position, tolerance, velocity);

    if (target != position.pixels) {
      return ScrollSpringSimulation(
        scrollPhysicsConfig.springDescription,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }

    return null;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final minExtent = minScrollBound ?? position.minScrollExtent;
    final maxExtent = maxScrollBound ?? position.maxScrollExtent;

    if (value < position.pixels && position.pixels <= minExtent) {
      return value - position.pixels;
    }
    if (maxExtent <= position.pixels && position.pixels < value) {
      return value - position.pixels;
    }
    if (value < minExtent && minExtent < position.pixels) {
      return value - minExtent;
    }
    if (position.pixels < maxExtent && maxExtent < value) {
      return value - maxExtent;
    }
    return 0.0;
  }

  @override
  bool get allowImplicitScrolling => false;
}
