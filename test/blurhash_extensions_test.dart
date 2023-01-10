import 'dart:io';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:blurhash_dart/blurhash_extensions.dart';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  test('check if dark picture is dark', () {
    final fileData = File('test/images/darkness_test_0.png').readAsBytesSync();
    final image = decodeImage(fileData);
    final blurHash = BlurHash.encode(image!, numCompX: 4, numCompY: 3);

    expect(blurHash.isDark, true);
    expect(blurHash.isLeftEdgeDark, true);
    expect(blurHash.isRightEdgeDark, true);
    expect(blurHash.isBottomEdgeDark, true);
    expect(blurHash.isTopEdgeDark, true);
    expect(blurHash.isTopLeftCornerDark, true);
    expect(blurHash.isTopRightCornerDark, true);
    expect(blurHash.isBottomLeftCornerDark, true);
    expect(blurHash.isBottomRightCornerDark, true);
  });

  test('check if light picture is not dark', () {
    final fileData = File('test/images/darkness_test_1.png').readAsBytesSync();
    final image = decodeImage(fileData);
    final blurHash = BlurHash.encode(image!, numCompX: 4, numCompY: 3);

    expect(blurHash.isDark, false);
    expect(blurHash.isLeftEdgeDark, false);
    expect(blurHash.isRightEdgeDark, false);
    expect(blurHash.isBottomEdgeDark, false);
    expect(blurHash.isTopEdgeDark, false);
    expect(blurHash.isTopLeftCornerDark, false);
    expect(blurHash.isTopRightCornerDark, false);
    expect(blurHash.isBottomLeftCornerDark, false);
    expect(blurHash.isBottomRightCornerDark, false);
  });

  test('check if mixed picture is sometimes dark', () {
    final fileData = File('test/images/darkness_test_2.png').readAsBytesSync();
    final image = decodeImage(fileData);
    final blurHash = BlurHash.encode(image!, numCompX: 4, numCompY: 3);

    expect(blurHash.isDark, false);
    expect(blurHash.isLeftEdgeDark, true);
    expect(blurHash.isRightEdgeDark, false);
    expect(blurHash.isBottomEdgeDark, false);
    expect(blurHash.isTopEdgeDark, false);
    expect(blurHash.isTopLeftCornerDark, true);
    expect(blurHash.isTopRightCornerDark, false);
    expect(blurHash.isBottomLeftCornerDark, true);
    expect(blurHash.isBottomRightCornerDark, false);
  });
}
