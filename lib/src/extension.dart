
import 'dart:math';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:blurhash_dart/src/foundation.dart';

extension BlurHashUtilExtension on BlurHash {
  static const _defaultThreshold = 0.3;

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

  bool get isDark => isAverageDark();

  bool get isLeftEdgeDark => isDarkAtX(0);

  bool get isRightEdgeDark => isDarkAtX(numCompX - 1);

  bool get isTopEdgeDark => isDarkAtY(0);

  bool get isBottomEdgeDark => isDarkAtY(numCompY - 1);

  bool get isTopLeftCornerDark => isDarkAtPos(0, 0);

  bool get isTopRightCornerDark => isDarkAtPos(numCompX - 1, 0);

  bool get isBottomLeftCornerDark => isDarkAtPos(0, numCompY - 1);

  bool get isBottomRightCornerDark => isDarkAtPos(numCompX - 1, numCompY - 1);

  bool isAverageDark({double? threshold}) =>
      _getDarkness(components[0][0], threshold);

  bool isDarkAtX(int x, {double? threshold}) =>
      _getDarkness(_linearRGBAtX(x), threshold);

  bool isDarkAtY(int y, {double? threshold}) =>
      _getDarkness(_linearRGBAtY(y), threshold);

  bool isDarkAtPos(int x, int y, {double? threshold}) =>
      _getDarkness(_linearRGBAtPos(x, y), threshold);

  bool isDiagonalDark(
      Point<int> topLeftCorner,
      Point<int> bottomRightCorner, {
        double? threshold,
      }) {
    return _getDarkness(
      _linearRGBAtDiagonal(topLeftCorner, bottomRightCorner),
      threshold,
    );
  }

  static bool _getDarkness(ColorTriplet color, double? threshold) {
    return color.r * 0.299 + color.g * 0.587 + color.b * 0.114 <
        (threshold ?? _defaultThreshold);
  }

  ColorTriplet _linearRGBAtX(int x) {
    if (x < 0 || x >= numCompX) {
      throw ArgumentError(
          'The given x-coordinate is out of range of the components.');
    }

    var i = 0;
    var sum = ColorTriplet(0, 0, 0);
    for (final component in components[0]) {
      sum += component * cos(pi * i++ * x);
    }
    return sum;
  }

  ColorTriplet _linearRGBAtY(int y) {
    if (y < 0 || y >= numCompY) {
      throw ArgumentError(
          'The given y-coordinate is out of range of the components.');
    }

    var i = 0;
    var sum = ColorTriplet(0, 0, 0);
    for (final horizontalComponents in components) {
      sum += horizontalComponents[0] * cos(pi * i++ * y);
    }
    return sum;
  }

  ColorTriplet _linearRGBAtPos(int x, int y) {
    if (x < 0 || x >= numCompX) {
      throw ArgumentError(
          'The given x-coordinate is out of range of the components.');
    }
    if (y < 0 || y >= numCompY) {
      throw ArgumentError(
          'The given y-coordinate is out of range of the components.');
    }

    var sum = ColorTriplet(0, 0, 0);
    for (var j = 0; j < numCompY; j++) {
      for (var i = 0; i < numCompX; i++) {
        sum += components[j][i] * cos(pi * i * x) * cos(pi * j * y);
      }
    }
    return sum;
  }

  ColorTriplet _linearRGBAtDiagonal(
      Point<int> topLeftCorner,
      Point<int> bottomRightCorner,
      ) {
    if (topLeftCorner.x < 0 ||
        topLeftCorner.x >= numCompX ||
        topLeftCorner.y < 0 ||
        topLeftCorner.y >= numCompY) {
      throw ArgumentError('The coordinates of the top-left corner '
          'are out of range of the components.');
    }

    if (bottomRightCorner.x < 0 ||
        bottomRightCorner.x >= numCompX ||
        bottomRightCorner.y < 0 ||
        bottomRightCorner.y >= numCompY) {
      throw ArgumentError('The coordinates of the bottom-right corner '
          'are out of range of the components.');
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
}
