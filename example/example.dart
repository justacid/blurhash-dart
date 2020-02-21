import 'dart:typed_data';

import 'package:blurhash_dart/blurhash.dart';

void main() {
  String blurHash = "LEHV6nWB2yk8pyo0adR*.7kCMdnj";
  Uint8List bitmap = decodeBlurHash(blurHash, 35, 20);
  print("Do something with the $bitmap...");
}
