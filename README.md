# BlurHash Dart

A pure dart implementation of BlurHash without any external dependencies (except for
running tests) for maximum flexibility. Supports encoding and decoding. See
[BlurHash](https://blurha.sh/) website or [GitHub
repository](https://github.com/woltapp/blurhash) for more information.

The encoder of this dart implementation produces slightly different hashes than the
TypeScript implementation but matches the official C and Python implementation. In
practice this should not be relevant.

## Basic usage

### Decoding a BlurHash

```dart
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart';

String hash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
BlurHash blurHash = BlurHash.decode(hash);
Image image = blurHash.toImage(35, 20);

print(blurHash.hash);
```

### Encoding a BlurHash

```dart
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart';

Uint8List fileData = File("some_image.png").readAsBytesSync();
Image image = decodeImage(fileData.toList());
BlurHash blurHash = BlurHash.encode(image.getBytes(format: Format.rgba));

print(blurHash.hash);
```
