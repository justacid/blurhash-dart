import 'dart:typed_data';

import 'package:blurhash_dart/blurhash_dart.dart';

void main() {
  String hash = "LEHV6nWB2yk8pyo0adR*.7kCMdnj";
  BlurHash blurHash = BlurHash.fromString(hash);
  Uint8List bitmap = blurHash.toBitmap(35,20);
  print("Do something with the $bitmap...");
}
