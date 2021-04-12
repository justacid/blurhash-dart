import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart';

import 'encoding.dart';
import 'exception.dart';
import 'foundation.dart';

class BlurHash {
  /// The actual BlurHash string.
  final String hash;

  /// The decoded components of the BlurHash.
  /// This is mostly useful for e.g. transposing a BlurHash.
  final List<List<ColorTriplet>> components;

  /// The number of horizontal BlurHash components.
  final int numCompX;

  /// The number of vertical BlurHash components.
  final int numCompY;

  /// Private constructor used in the actual factory constructors.
  /// See [BlurHash.decode] and [BlurHash.encode].
  BlurHash._(
    this.hash,
    this.components,
  )   : assert(components.isNotEmpty),
        assert(components[0].isNotEmpty),
        numCompY = components.length,
        numCompX = components[0].length;

  /// Construct a [BlurHash] object from decoded components.
  /// This is useful for e.g. transposing a BlurHash.
  BlurHash.components(this.components)
      : assert(components.isNotEmpty),
        assert(components[0].isNotEmpty),
        hash = _encodeComponents(components),
        numCompX = components[0].length,
        numCompY = components.length;

  /// Decode a BlurHash String to a BlurHash object.
  ///
  /// The [punch] parameter adjusts the contrast on the decoded image. Values
  /// less than 1 will make the effect more subtle, larger values will make the
  /// effect stronger. This is a design parameter to adjust the look.
  ///
  /// Throws [BlurHashDecodeException] when an invalid BlurHash is encountered.
  factory BlurHash.decode(String blurHash, {double punch = 1.0}) {
    if (blurHash.length < 6) {
      throw BlurHashDecodeException(
        "BlurHash must not be null or '< 6' characters long.",
      );
    }
    final sizeFlag = decode83(blurHash, 0, 1);
    final numCompX = (sizeFlag % 9) + 1;
    final numCompY = (sizeFlag ~/ 9) + 1;

    if (blurHash.length != 4 + 2 * numCompX * numCompY) {
      throw BlurHashDecodeException(
        'Invalid number of components in BlurHash.',
      );
    }

    final maxAcEnc = decode83(blurHash, 1, 2);
    final maxAc = (maxAcEnc + 1) / 166.0;
    final components = List.generate(
      numCompY,
      (i) => List<ColorTriplet>.filled(numCompX, ColorTriplet(0, 0, 0)),
    );

    for (var j = 0; j < numCompY; j++) {
      for (var i = 0; i < numCompX; i++) {
        if (i == 0 && j == 0) {
          final value = decodeDc(decode83(blurHash, 2, 6));
          components[j][i] = value;
        } else {
          final index = i + j * numCompX;
          final value = decodeAc(
            decode83(blurHash, 4 + index * 2, (4 + index * 2) + 2),
            maxAc,
          );
          components[j][i] = value;
        }
      }
    }

    return BlurHash._(blurHash, _multiplyPunch(components, punch));
  }

  /// Encodes an image to a BlurHash string.
  ///
  /// The parameters [numCompX] and [numCompY] are the number of components of
  /// the BlurHash. Both parameters must be between 1 and 9. Throws a
  /// [BlurHashEncodeException] when [numCompX] and [numCompY] are not in
  /// the expected range.
  factory BlurHash.encode(
    Image image, {
    int numCompX = 4,
    int numCompY = 3,
  }) {
    if (numCompX < 1 || numCompX > 9 || numCompY < 1 || numCompY > 9) {
      throw BlurHashEncodeException(
        'BlurHash components must be between 1 and 9.',
      );
    }

    final data = image.getBytes(format: Format.rgba);
    final components = List.generate(
      numCompY,
      (i) => List<ColorTriplet>.filled(numCompX, ColorTriplet(0, 0, 0)),
    );

    for (var y = 0; y < numCompY; ++y) {
      for (var x = 0; x < numCompX; ++x) {
        final normalisation = (x == 0 && y == 0) ? 1.0 : 2.0;
        final basisFunc = (int i, int j) {
          return normalisation *
              cos((pi * x * i) / image.width) *
              cos((pi * y * j) / image.height);
        };
        components[y][x] =
            _multiplyBasisFunction(data, image.width, image.height, basisFunc);
      }
    }

    final hash = _encodeComponents(components);
    return BlurHash._(hash, components);
  }

  /// Construct a [BlurHash] with a single color.
  ///
  /// The RGB values must be in range [0, 255].
  factory BlurHash.fromRgb(int red, int green, int blue) {
    assert(red >= 0 && red <= 255);
    assert(green >= 0 && green <= 255);
    assert(blue >= 0 && blue <= 255);

    final color = ColorTriplet(
      sRgbToLinear(red),
      sRgbToLinear(green),
      sRgbToLinear(blue),
    );

    return BlurHash.components([
      [color]
    ]);
  }

  /// Returns the actual [BlurHash] image with the given [width] and [height].
  ///
  /// The [width] and [height] must not be null and greater than 0. It is
  /// recommended to keep the [width] and [height] small and let the UI layer
  /// handle upscaling for better performance.
  Image toImage(int width, int height) {
    assert(width > 0);
    assert(height > 0);
    final data = _transform(width, height, components);
    return Image.fromBytes(width, height, data, format: Format.rgba);
  }
}

/// Deprecated. Please use [BlurHash.decode] and [BlurHash.toImage] instead.
/// Decode a BlurHash to raw pixels in RGBA32 format
@deprecated
Uint8List decodeBlurHash(
  String blurHash,
  int width,
  int height, {
  double punch = 1.0,
}) {
  final hash = BlurHash.decode(blurHash, punch: punch);
  return hash.toImage(width, height).getBytes(format: Format.rgba);
}

/// Deprecated. Please use [BlurHash.encode] instead.
/// Encodes an image to a BlurHash string
@deprecated
String encodeBlurHash(
  Uint8List data,
  int width,
  int height, {
  int numCompX = 4,
  int numpCompY = 3,
}) {
  final image = Image.fromBytes(width, height, data, format: Format.rgba);
  final hash = BlurHash.encode(image, numCompX: numCompX, numCompY: numpCompY);
  return hash.hash;
}

String _encodeComponents(List<List<ColorTriplet>> components) {
  final numCompX = components[0].length;
  final numCompY = components.length;

  final factors = List<ColorTriplet>.filled(
    numCompX * numCompY,
    ColorTriplet(0, 0, 0),
  );

  var count = 0;
  for (var i = 0; i < numCompY; i++) {
    for (var j = 0; j < numCompX; j++) {
      factors[count++] = components[i][j];
    }
  }

  return _encodeFactors(factors, numCompX, numCompY);
}

String _encodeFactors(
  List<ColorTriplet> factors,
  int numCompX,
  int numCompY,
) {
  final dc = factors.first;
  final ac = factors.skip(1).toList();

  final blurHash = StringBuffer();
  final sizeFlag = (numCompX - 1) + (numCompY - 1) * 9;
  blurHash.write(encode83(sizeFlag, 1));

  var maxVal = 1.0;
  if (ac.isNotEmpty) {
    final maxElem =
        (ColorTriplet c) => max(c.r.abs(), max(c.g.abs(), c.b.abs()));
    final actualMax = ac.map(maxElem).reduce(max);
    final quantisedMax = max(0, min(82, (actualMax * 166.0 - 0.5).floor()));
    maxVal = (quantisedMax + 1.0) / 166.0;
    blurHash.write(encode83(quantisedMax, 1));
  } else {
    blurHash.write(encode83(0, 1));
  }

  blurHash.write(encode83(encodeDc(dc), 4));
  for (final factor in ac) {
    blurHash.write(encode83(encodeAc(factor, maxVal), 2));
  }
  return blurHash.toString();
}

List<List<ColorTriplet>> _multiplyPunch(
  List<List<ColorTriplet>> components,
  double factor,
) {
  for (var i = 0; i < components.length; i++) {
    for (var j = 0; j < components[i].length; j++) {
      if (i != 0 && j != 0) {
        components[i][j] = components[i][j] * factor;
      }
    }
  }
  return components;
}

Uint8List _transform(
  int width,
  int height,
  List<List<ColorTriplet>> components,
) {
  final pixels = List<int>.filled(width * height * 4, 0);

  var pixel = 0;
  for (var y = 0; y < height; ++y) {
    for (var x = 0; x < width; ++x) {
      var r = 0.0;
      var g = 0.0;
      var b = 0.0;

      for (var j = 0; j < components.length; ++j) {
        for (var i = 0; i < components[0].length; ++i) {
          final basis = cos(pi * x * i / width) * cos(pi * y * j / height);
          final color = components[j][i];
          r += color.r * basis;
          g += color.g * basis;
          b += color.b * basis;
        }
      }

      pixels[pixel++] = linearTosRgb(r);
      pixels[pixel++] = linearTosRgb(g);
      pixels[pixel++] = linearTosRgb(b);
      pixels[pixel++] = 255;
    }
  }

  return Uint8List.fromList(pixels);
}

ColorTriplet _multiplyBasisFunction(
  Uint8List pixels,
  int width,
  int height,
  double Function(int i, int j) basisFunction,
) {
  var r = 0.0;
  var g = 0.0;
  var b = 0.0;

  final bytesPerRow = width * 4;

  for (var x = 0; x < width; ++x) {
    for (var y = 0; y < height; ++y) {
      final basis = basisFunction(x, y);
      r += basis * sRgbToLinear(pixels[4 * x + 0 + y * bytesPerRow]);
      g += basis * sRgbToLinear(pixels[4 * x + 1 + y * bytesPerRow]);
      b += basis * sRgbToLinear(pixels[4 * x + 2 + y * bytesPerRow]);
    }
  }

  final scale = 1.0 / (width * height);
  return ColorTriplet(r * scale, g * scale, b * scale);
}
