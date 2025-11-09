# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2025-11-09

### Fixed
- Fixed `visibleLabels` not working correctly when chart widget width is not full screen. Charts now properly use the constrained layout width instead of device screen width for all calculations, ensuring correct label visibility, scroll behavior, and pointer positioning in containers like `SizedBox`, `Expanded`, or `Row` with specific widths.

## [0.2.0] - 2025-01-07

### Added
- `LabelTransformer` typedef for customizing label formatting
- `defaultLabelTransformer` function that provides default label formatting
- `labelTransformer` parameter to both `LineChart` and `StackedAreaChart` widgets
- `LabelOverlapBehavior` enum with three strategies for handling overlapping line labels:
  - `none` - No overlap handling (default, maintains backward compatibility)
  - `adjust` - Smart collision detection that automatically adjusts label positions vertically
  - `hide` - Hides overlapping labels, showing only non-conflicting ones
- `overlapBehavior` parameter to `LineLabelStyle` for configuring label overlap strategy

### Changed
- **BREAKING**: `CumulativeLabelStyle` now uses `TextStyle textStyle` instead of separate `textColor`, `fontSize`, and `fontWeight` properties
- **BREAKING**: `XAxisLabelStyle` now uses `TextStyle textStyle` instead of separate `color`, `fontSize`, and `fontWeight` properties
- **BREAKING**: `LineLabelStyle` now uses `TextStyle textStyle` instead of separate `textColor`, `fontSize`, and `fontWeight` properties

### Migration Guide
To migrate from 0.1.0 to 0.2.0, update your style configurations:

```dart
// Before (0.1.0)
XAxisLabelStyle(
  color: Colors.black87,
  fontSize: 12.0,
  fontWeight: FontWeight.w500,
)

// After (0.2.0)
XAxisLabelStyle(
  textStyle: TextStyle(
    color: Colors.black87,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
  ),
)
```

## [0.1.0] - 2025-01-07

### Added
- Initial release of Scrollable Charts
- LineChart widget with smooth scrolling and animations
- StackedAreaChart widget for cumulative data visualization
- Extensive customization options:
  - Grid lines (solid and dashed)
  - Data markers (8 different shapes)
  - Custom colors and styling
  - X-axis and zero-line customization
  - Data labels with positioning
- Animation system:
  - Smooth Y-axis range animations
  - Configurable animation curves and durations
  - Scroll snap physics
- Data handling features:
  - Support for missing data points
  - Multiple lines/areas per chart
  - Callbacks for visible range and selection changes
- Comprehensive documentation and examples