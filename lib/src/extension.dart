import 'dart:math';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:blurhash_dart/src/foundation.dart';

extension BlurHashExtensions on BlurHash {
  /// Transposes the [BlurHash].
  BlurHash get transposed {
    final numCompX = components[0].length;
    final numCompY = components.length;
    final transposedComponents = List.generate(
      numCompX,
      (i) => List<ColorTriplet>.filled(numCompY, ColorTriplet(0, 0, 0)),
    );
    for (var j = 0; j < numCompY; j++) {
      for (var i = 0; i < numCompX; i++) {
        transposedComponents[i][j] = components[j][i];
      }
    }
    return BlurHash.components(transposedComponents);
  }

  /// Mirrors the [BlurHash] horizontally.
  BlurHash get mirroredHorizontally {
    final numCompX = components[0].length;
    final numCompY = components.length;
    final mirroredComponents = List.generate(
      numCompY,
      (i) => List<ColorTriplet>.filled(numCompX, ColorTriplet(0, 0, 0)),
    );
    for (var j = 0; j < numCompY; j++) {
      for (var i = 0; i < numCompX; i++) {
        mirroredComponents[j][i] = components[j][i] * (i % 2 == 0 ? 1 : -1);
      }
    }
    return BlurHash.components(mirroredComponents);
  }

  /// Mirrors the [BlurHash] vertically.
  BlurHash get mirroredVertically {
    final numCompX = components[0].length;
    final numCompY = components.length;
    final mirroredComponents = List.generate(
      numCompY,
      (i) => List<ColorTriplet>.filled(numCompX, ColorTriplet(0, 0, 0)),
    );
    for (var j = 0; j < numCompY; j++) {
      for (var i = 0; i < numCompX; i++) {
        mirroredComponents[j][i] = components[j][i] * (j % 2 == 0 ? 1 : -1);
      }
    }
    return BlurHash.components(mirroredComponents);
  }

  /// Returns whether the average brightness is considered dark.
  /// See [BlurHashExtensions.isAverageDark] to set a custom threshold.
  bool get isDark => isAverageDark();

  /// Returns whether the left edge is considered dark.
  /// See [BlurHashExtensions.isDarkAtX] to set a custom threshold.
  bool get isLeftEdgeDark => isDarkAtX(0.0);

  /// Returns whether the right edge is considered dark.
  /// See [BlurHashExtensions.isDarkAtX] to set a custom threshold.
  bool get isRightEdgeDark => isDarkAtX(1.0);

  /// Returns whether the top edge is considered dark.
  /// See [BlurHashExtensions.isDarkAtY] to set a custom threshold.
  bool get isTopEdgeDark => isDarkAtY(0.0);

  /// Returns whether the bottom edge is considered dark.
  /// See [BlurHashExtensions.isDarkAtY] to set a custom threshold.
  bool get isBottomEdgeDark => isDarkAtY(1.0);

  /// Returns whether the top-left corner is considered dark.
  /// See [BlurHashExtensions.isDarkAtPos] to set a custom threshold.
  bool get isTopLeftCornerDark => isDarkAtPos(0.0, 0.0);

  /// Returns whether the top-right corner is considered dark.
  /// See [BlurHashExtensions.isDarkAtPos] to set a custom threshold.
  bool get isTopRightCornerDark => isDarkAtPos(1.0, 0.0);

  /// Returns whether the bottom-left corner is considered dark.
  /// See [BlurHashExtensions.isDarkAtPos] to set a custom threshold.
  bool get isBottomLeftCornerDark => isDarkAtPos(0.0, 1.0);

  /// Returns whether the bottom-right corner is considered dark.
  /// See [BlurHashExtensions.isDarkAtPos] to set a custom threshold.
  bool get isBottomRightCornerDark => isDarkAtPos(1.0, 1.0);

  /// Returns whether the given color is considered dark.
  /// The color must be given as a linear RGB color.
  bool isColorDark(ColorTriplet color, {double threshold = 0.3}) =>
      _getDarkness(color, threshold);

  /// Returns whether the average brightness is considered dark.
  bool isAverageDark({double? threshold}) =>
      _getDarkness(averageLinearRgb, threshold);

  /// Returns whether the given row is considered dark.
  ///
  /// {@template ext_valid_args}
  /// Coordinates are given in percent and must be between 0 and 1.
  /// Throws [ArgumentError] if the coordinates are out of range.
  /// {@endtemplate}
  bool isDarkAtX(double x, {double? threshold}) =>
      _getDarkness(linearRgbAtX(x), threshold);

  /// Returns whether the given row is considered dark.
  ///
  /// {@macro ext_valid_args}
  bool isDarkAtY(double y, {double? threshold}) =>
      _getDarkness(linearRgbAtY(y), threshold);

  /// Returns whether the given point is considered dark.
  ///
  /// {@macro ext_valid_args}
  bool isDarkAtPos(double x, double y, {double? threshold}) =>
      _getDarkness(linearRgbAt(x, y), threshold);

  /// Returns whether the given rectangular region is considered dark.
  ///
  /// {@macro ext_valid_args}
  bool isRectDark(
    Point<double> topLeftCorner,
    Point<double> bottomRightCorner, {
    double? threshold,
  }) {
    return _getDarkness(
      linearRgbInRect(topLeftCorner, bottomRightCorner),
      threshold,
    );
  }

  /// Returns the average linear RGB.
  ///
  /// {@template linear_vs_srgb}
  /// [ColorTriplet] by default is in linear RGB color space. Convert to
  /// RGB before using the color. See [ColorTripletExtensions.toRgb].
  /// {@endtemplate}
  ColorTriplet get averageLinearRgb => components[0][0];

  /// Returns linear RGB for the given column.
  ///
  /// {@macro ext_valid_args}
  /// {@macro linear_vs_srgb}
  ColorTriplet linearRgbAtX(double x) {
    if (x < 0.0 || x > 1.0) {
      throw ArgumentError('Coordinates must be between [0, 1].');
    }

    var i = 0;
    var sum = ColorTriplet(0, 0, 0);
    for (final component in components[0]) {
      sum += component * cos(pi * i++ * x);
    }
    return sum;
  }

  /// Returns linear RGB for the given row.
  ///
  /// {@macro ext_valid_args}
  /// {@macro linear_vs_srgb}
  ColorTriplet linearRgbAtY(double y) {
    if (y < 0.0 || y > 1.0) {
      throw ArgumentError('Coordinates must be between [0, 1].');
    }

    var i = 0;
    var sum = ColorTriplet(0, 0, 0);
    for (final horizontalComponents in components) {
      sum += horizontalComponents[0] * cos(pi * i++ * y);
    }
    return sum;
  }

  /// Returns linear RGB for a point.
  ///
  /// {@macro ext_valid_args}
  /// {@macro linear_vs_srgb}
  ColorTriplet linearRgbAt(double x, double y) {
    if (x < 0.0 || x > 1.0 || y < 0.0 || y > 1.0) {
      throw ArgumentError('Coordinates must be between [0, 1].');
    }

    var sum = ColorTriplet(0, 0, 0);
    for (var j = 0; j < numCompY; j++) {
      for (var i = 0; i < numCompX; i++) {
        sum += components[j][i] * cos(pi * i * x) * cos(pi * j * y);
      }
    }
    return sum;
  }

  /// Returns linear RGB for a rectangular region.
  ///
  /// {@macro ext_valid_args}
  /// {@macro linear_vs_srgb}
  ColorTriplet linearRgbInRect(
    Point<double> topLeftCorner,
    Point<double> bottomRightCorner,
  ) {
    if (topLeftCorner.x < 0.0 ||
        topLeftCorner.x > 1.0 ||
        topLeftCorner.y < 0.0 ||
        topLeftCorner.y > 1.0) {
      throw ArgumentError('Coordinates must be between [0, 1].');
    }

    if (bottomRightCorner.x < 0.0 ||
        bottomRightCorner.x > 1.0 ||
        bottomRightCorner.y < 0.0 ||
        bottomRightCorner.y > 1.0) {
      throw ArgumentError('Coordinates must be between [0, 1].');
    }

    if (topLeftCorner.x >= bottomRightCorner.x ||
        topLeftCorner.y >= bottomRightCorner.y) {
      throw ArgumentError('The bottom-right corner must be right of '
          'and below to the top-left corner!');
    }

    var sum = ColorTriplet(0, 0, 0);
    for (var j = 0; j < numCompY; j++) {
      for (var i = 0; i < numCompX; i++) {
        final horizontalAverage = i == 0
            ? 1.0
            : ((sin(pi * i * bottomRightCorner.x) -
                    sin(pi * i * topLeftCorner.x)) /
                (i * pi * (bottomRightCorner.x - topLeftCorner.x)));
        final verticalAverage = j == 0
            ? 1.0
            : ((sin(pi * j * bottomRightCorner.y) -
                    sin(pi * j * topLeftCorner.y)) /
                (j * pi * (bottomRightCorner.y - topLeftCorner.y)));
        sum += components[j][i] * horizontalAverage * verticalAverage;
      }
    }
    return sum;
  }

  static const _defaultThreshold = 0.3;

  static bool _getDarkness(ColorTriplet color, double? threshold) {
    return color.r * 0.299 + color.g * 0.587 + color.b * 0.114 <
        (threshold ?? _defaultThreshold);
  }
}

extension ColorTripletExtensions on ColorTriplet {
  /// Returns new [ColorTriplet], converted from linear RGB to sRGB.
  /// After conversion the color components will be between [0, 255].
  ColorTriplet toRgb() {
    return ColorTriplet(
      linearTosRgb(r).toDouble(),
      linearTosRgb(g).toDouble(),
      linearTosRgb(b).toDouble(),
    );
  }
}
