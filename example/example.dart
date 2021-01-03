import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:blurhash_dart/blurhash_utils.dart';

void main() {
  const hash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
  final blurHash = BlurHash.decode(hash);

  final image = blurHash.toImage(35, 20);
  print('The BlurHash has size: ${image.width}x${image.height}.');

  // Import 'package:blurhash_dart/blurhash_utils.dart' to use the utility
  // extension methods, for example:
  print('The average color tone is dark: ${blurHash.isDark}');
  print('The left image edge is dark: ${blurHash.isLeftEdgeDark}');
}
