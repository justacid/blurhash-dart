# BlurHash Dart

A pure dart implementation of BlurHash. Supports both encoding and decoding. Runs on
every supported Dart platform. See the [BlurHash](https://blurha.sh/) website or [GitHub
repository](https://github.com/woltapp/blurhash) for more information.

The encoder of this dart implementation produces slightly different hashes than the
TypeScript implementation but matches the official C and Python implementation. In
practice this should not be relevant.

## Basic usage

### Decoding a BlurHash

```dart
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img;

const hash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
BlurHash blurHash = BlurHash.decode(hash);
img.Image image = blurHash.toImage(35, 20);

// Display image...
```

### Encoding an Image

```dart
import 'dart:io';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img;

final data = File('path/to/image.png').readAsBytesSync();
final image = img.decodeImage(data.toList());
final blurHash = BlurHash.encode(image!, numCompX: 4, numCompY: 3);

print(blurHash.hash);
```

### Extension Methods

Additional extension methods to compute, for example color averages, are available
when importing `package:blurhash_dart/blurhash_extensions.dart`. See example for
basic usage.
