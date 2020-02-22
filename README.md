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

Decoding a BlurHash returns a raw array of pixels in RGBA32 format. You must convert
the data to an image yourself. For this example we use the
[bitmap](https://pub.dev/packages/bitmap) package to convert the pixel array to an
bitmap, then to an ui.Image.

```dart
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:bitmap/bitmap.dart';

import 'dart:ui' as ui; // for displaying the image
//..

String blurHash = "LEHV6nWB2yk8pyo0adR*.7kCMdnj";
Uint8List pixels = decodeBlurHash(blurHash, 35, 20);

Bitmap bitmap = Bitmap.fromHeadless(35, 20, pixels);
ui.Image image = await bitmap.buildImage();
//..
```

### Encoding a BlurHash

For demo purposes we assume to have the popular [image](https://pub.dev/packages/image)
package installed, which decodes image files. The blurhash-dart API expects raw pixels
in RGBA32 format for maximum flexibility.

```dart
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img; // for demo purposes
//..

Uint8List fileData = File("some_image.png").readAsBytesSync();
img.Image image = img.decodeImage(fileData.toList());

final blurHash = encodeBlurHash(
  image.getBytes(format: Format.rgba),
  image.width,
  image.height,
);

print("$blurHash");
```
