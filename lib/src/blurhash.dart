import 'dart:math';
import 'dart:typed_data';

import 'bitmap.dart';
import 'encoding.dart';
import 'exception.dart';
import 'foundation.dart';

/// Decode a BlurHash to bitmap
///
/// Decodes a [blurHash] to a bitmap file with specified [width] and [height]. Both
/// [width] and [height] must not be null and greater than 0. It is recommended to keep
/// the [width] and [height] small and let the UI layer handle upscaling for better
/// performance.
///
/// The [punch] parameters adjusts the contrast on the decoded image. Values less than 1
/// will make the effect more subtle, larger values will make the effect stronger. This
/// is a design paramter to adjust the look.
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

  final bytes = _transform(width, height, numCompX, numCompY, colors);
  return buildBitmap(bytes, width, height);
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
