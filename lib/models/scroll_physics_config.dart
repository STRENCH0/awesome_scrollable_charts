import 'package:flutter/material.dart';

class ScrollPhysicsConfig {
  final double mass;
  final double stiffness;
  final double damping;

  const ScrollPhysicsConfig({
    this.mass = 1.0,
    this.stiffness = 180.0,
    this.damping = 20.0,
  });

  SpringDescription get springDescription => SpringDescription(
        mass: mass,
        stiffness: stiffness,
        damping: damping,
      );

  static const ScrollPhysicsConfig smooth = ScrollPhysicsConfig(
    mass: 1.0,
    stiffness: 180.0,
    damping: 30.0,
  );

  static const ScrollPhysicsConfig bouncy = ScrollPhysicsConfig(
    mass: 0.5,
    stiffness: 100.0,
    damping: 8.0,
  );

  static const ScrollPhysicsConfig fast = ScrollPhysicsConfig(
    mass: 0.8,
    stiffness: 200.0,
    damping: 18.0,
  );
}
