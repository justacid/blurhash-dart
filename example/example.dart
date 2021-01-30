import 'dart:math';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:blurhash_dart/blurhash_extensions.dart';

void main() {
  // Decode a BlurHash.
  const hash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
  final blurHash = BlurHash.decode(hash);

  // Generate an image with size 35x20.
  final image = blurHash.toImage(35, 20);
  print('The BlurHash image has size: ${image.width}x${image.height}.');

  // Import 'package:blurhash_dart/blurhash_extensions.dart'
  // to use the utility extensions.
  print('The average color tone is dark: ${blurHash.isDark}');
  print('The left image edge is dark: ${blurHash.isLeftEdgeDark}');

  // Using the extension methods allows fast retrieval of average colors. For
  // example, to get the average color in a rectangular region we first define
  // a rectangle that is inset by twenty percent to each edge of the original
  // BlurHash and retrieve the average linear RGB within that region.
  final topLeftCorner = Point(0.2, 0.2);
  final bottomRightCorner = Point(0.8, 0.8);
  final triplet = blurHash.linearRgbInRect(topLeftCorner, bottomRightCorner);

  // Convert to sRGB before displaying. Values will be between [0, 255].
  final color = triplet.toRgb();
  print('Color(${color.r}, ${color.g}, ${color.b}');
}
