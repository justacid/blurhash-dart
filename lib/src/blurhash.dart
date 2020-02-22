import 'dart:math';
import 'dart:typed_data';

import 'encoding.dart';
import 'exception.dart';
import 'foundation.dart';

/// Decode a BlurHash to raw pixels in RGBA32 format
///
/// Decodes a [blurHash] to raw pixels in RGBA32 format with specified [width] and
/// [height]. Both [width] and [height] must not be null and greater than 0. It is
/// recommended to keep the [width] and [height] small and let the UI layer handle
/// upscaling for better performance.
///
/// The [punch] parameter adjusts the contrast on the decoded image. Values less than 1
/// will make the effect more subtle, larger values will make the effect stronger. This
/// is a design parameter to adjust the look.
///
/// Throws [BlurHashDecodeException] when an invalid BlurHash is encountered.
Uint8List decodeBlurHash(
  String blurHash,
  int width,
  int height, {
  double punch = 1.0,
}) {
  assert(width != null && width > 0);
  assert(height != null && height > 0);

  if (blurHash == null || blurHash.length < 6) {
    throw BlurHashDecodeException(
      message: "BlurHash must not be null or '< 6' characters long.",
    );
  }

  final sizeFlag = decode83(blurHash, 0, 1);
  final numCompX = (sizeFlag % 9) + 1;
  final numCompY = (sizeFlag ~/ 9) + 1;

  if (blurHash.length != 4 + 2 * numCompX * numCompY) {
    throw BlurHashDecodeException(
      message: "Invalid number of components in BlurHash.",
    );
  }

  final maxAcEnc = decode83(blurHash, 1, 2);
  final maxAc = (maxAcEnc + 1) / 166.0;

  final colors = List<Color>(numCompX * numCompY);
  colors[0] = decodeDC(decode83(blurHash, 2, 6));
  for (var i = 1; i < numCompX * numCompY; ++i) {
    colors[i] = decodeAC(
      decode83(blurHash, 4 + i * 2, (4 + i * 2) + 2),
      maxAc * punch,
    );
  }

  return _transform(width, height, numCompX, numCompY, colors);
}

/// Encodes an image to a BlurHash string
///
/// The format of the given [data] array is expected to be raw pixels in RGBA32 format -
/// without any additional image headers. The [width] and [height] are the dimensions of
/// the given image. Parameters [numCompX] and [numCompY] are the components of the
/// BlurHash. Both parameters must lie between 1 and 9.
///
/// Throws [BlurHashEncodeException] when [numCompX] and [numCompY] do not lie within the
/// expected range. Also throws [BlurHashEncodeException] when the [data] array is not in
/// the expected RGBA32 format.
String encodeBlurHash(
  Uint8List data,
  int width,
  int height, {
  int numCompX = 4,
  int numpCompY = 3,
}) {
  if (numCompX < 1 || numCompX > 9 || numpCompY < 1 || numCompX > 9) {
    throw BlurHashEncodeException(
      message: "BlurHash components must lie between 1 and 9.",
    );
  }

  if (width * height * 4 != data.length) {
    throw BlurHashEncodeException(
      message: "The width and height must match the data array."
          "The expected format is RGBA32",
    );
  }

  final factors = List<Color>(numCompX * numpCompY);
  int i = 0;
  for (var y = 0; y < numpCompY; ++y) {
    for (var x = 0; x < numCompX; ++x) {
      final normalisation = (x == 0 && y == 0) ? 1.0 : 2.0;
      final basisFunc = (int i, int j) {
        return normalisation *
            cos((pi * x * i) / width) *
            cos((pi * y * j) / height);
      };
      factors[i++] = _multiplyBasisFunction(data, width, height, basisFunc);
    }
  }

  final dc = factors.first;
  final ac = factors.skip(1).toList();

  final blurHash = StringBuffer();
  final sizeFlag = (numCompX - 1) + (numpCompY - 1) * 9;
  blurHash.write(encode83(sizeFlag, 1));

  var maxVal = 1.0;
  if (ac.isNotEmpty) {
    final maxElem = (Color c) => max(c.r.abs(), max(c.g.abs(), c.b.abs()));
    final actualMax = ac.map(maxElem).reduce(max);
    final quantisedMax = max(0, min(82, (actualMax * 166.0 - 0.5).floor()));
    maxVal = (quantisedMax + 1.0) / 166.0;
    blurHash.write(encode83(quantisedMax, 1));
  } else {
    blurHash.write(encode83(0, 1));
  }

  blurHash.write(encode83(encodeDC(dc), 4));
  for (final factor in ac) {
    blurHash.write(encode83(encodeAC(factor, maxVal), 2));
  }
  return blurHash.toString();
}

Uint8List _transform(
  int width,
  int height,
  int numCompX,
  int numCompY,
  List<Color> colors,
) {
  final pixels = List<int>(width * height * 4);

  int pixel = 0;
  for (var y = 0; y < height; ++y) {
    for (var x = 0; x < width; ++x) {
      var r = 0.0;
      var g = 0.0;
      var b = 0.0;

      for (var j = 0; j < numCompY; ++j) {
        for (var i = 0; i < numCompX; ++i) {
          final basis = (cos(pi * x * i / width) * cos(pi * y * j / height));
          final color = colors[j * numCompX + i];
          r += color.r * basis;
          g += color.g * basis;
          b += color.b * basis;
        }
      }

      pixels[pixel++] = linearTosRGB(r);
      pixels[pixel++] = linearTosRGB(g);
      pixels[pixel++] = linearTosRGB(b);
      pixels[pixel++] = 255;
    }
  }

  return Uint8List.fromList(pixels);
}

Color _multiplyBasisFunction(
  Uint8List pixels,
  int width,
  int height,
  double basisFunction(int i, int j),
) {
  var r = 0.0;
  var g = 0.0;
  var b = 0.0;

  final bytesPerRow = width * 4;

  for (var x = 0; x < width; ++x) {
    for (var y = 0; y < height; ++y) {
      final basis = basisFunction(x, y);
      r += basis * sRGBtoLinear(pixels[4 * x + 0 + y * bytesPerRow]);
      g += basis * sRGBtoLinear(pixels[4 * x + 1 + y * bytesPerRow]);
      b += basis * sRGBtoLinear(pixels[4 * x + 2 + y * bytesPerRow]);
    }
  }

  final scale = 1.0 / (width * height);
  return Color(r * scale, g * scale, b * scale);
}
