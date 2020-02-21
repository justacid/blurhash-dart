# BlurHash Dart

A pure dart implementation of blurhash. Currently only supports decoding.
See the [blurhash](https://blurha.sh/) website for more information.

## Basic usage

Decoding a blurhash:

```dart
  String blurHash = "LEHV6nWB2yk8pyo0adR*.7kCMdnj";
  Uint8List bitmap = decodeBlurHash(blurHash, 35, 20);
```
