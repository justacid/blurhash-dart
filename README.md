# BlurHash Dart

A pure dart implementation of BlurHash without any external dependencies (except for
running tests). Supports encoding and decoding. See [BlurHash](https://blurha.sh/)
website or [GitHub Repository](https://github.com/woltapp/blurhash) for more
information.

## Basic usage

### Decoding a BlurHash

```dart
import 'package:blurhash_dart/blurhash.dart';

String blurHash = "LEHV6nWB2yk8pyo0adR*.7kCMdnj";
Uint8List bitmap = decodeBlurHash(blurHash, 35, 20);
```

### Encoding a BlurHash

For demo purposes we assume to have the popular [image](https://pub.dev/packages/image)
package installed, which decodes image files. The blurhash-dart API expects raw pixels
in RGBA32 format for maximum flexibility.

```dart
import 'package:blurhash_dart/blurhash.dart';
import 'package:image/image.dart' as img; // for demo purposes

Uint8List fileData = File("some_image.png").readAsBytesSync();
img.Image image = img.decodeImage(fileData.toList());

final blurHash = encodeBlurHash(
  image.getBytes(format: Format.rgba),
  image.width,
  image.height,
);

print("$blurHash");
```
