import 'dart:typed_data';

import 'package:blurhash_dart/blurhash_dart.dart';

void main() {
  String hash = "LEHV6nWB2yk8pyo0adR*.7kCMdnj";
  BlurHash blurHash = decodeBlurHash(hash, 35, 20);
  Uint8List bitmap = blurHash.toBitmap();
  print("Do something with the $bitmap...");
}
