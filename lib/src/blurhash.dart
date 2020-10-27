import 'dart:math';
import 'dart:typed_data';

import 'encoding.dart';
import 'exception.dart';
import 'foundation.dart';

class BlurHash {
  List<List<Color>> components;

  int numCompX;
  int numCompY;

  String blurHashString;

  bool isDark;
  bool isLeftEdgeDark;
  bool isRightEdgeDark;
  bool isTopEdgeDark;
  bool isBottomEdgeDark;
  bool isTopLeftCornerDark;
  bool isTopRightCornerDark;
  bool isBottomLeftCornerDark;
  bool isBottomRightCornerDark;

  BlurHash(this.components);

  void punch(factor){
    for(int i = 0; i < this.components.length; i++){
      for(int j = 0; j < this.components[i].length; j++){
        if(i!=0 && j!=0){
          this.components[i][j] = this.components[i][j] * factor;
        }
      }
    }
  }

  /// Decode a BlurHash String to a BlurHash object
  ///
  /// The [punch] parameter adjusts the contrast on the decoded image. Values less than 1
  /// will make the effect more subtle, larger values will make the effect stronger. This
  /// is a design parameter to adjust the look.
  ///
  /// Throws [BlurHashDecodeException] when an invalid BlurHash is encountered.
  BlurHash.fromString(
    String blurHash, {
    double punch = 1.0
  }){
    if (blurHash == null || blurHash.length < 6) {
      throw BlurHashDecodeException(
        message: "BlurHash must not be null or '< 6' characters long.",
      );
    }
    final sizeFlag = decode83(blurHash, 0, 1);
    this.numCompX = (sizeFlag % 9) + 1;
    this.numCompY = (sizeFlag ~/ 9) + 1;
    this.blurHashString = blurHash;

    if (blurHash.length != 4 + 2 * numCompX * numCompY) {
      throw BlurHashDecodeException(
        message: "Invalid number of components in BlurHash.",
      );
    }

    final maxAcEnc = decode83(blurHash, 1, 2);
    final maxAc = (maxAcEnc + 1) / 166.0;
    var components = List.generate(this.numCompY, (i) => List<Color>(numCompX));
    for(int j = 0; j < this.numCompY; j++){
      for(int i = 0; i < this.numCompX; i++){
        if(i == 0 && j == 0){
          final value = decodeDC(decode83(blurHash, 2, 6));
          components[j][i] = value;
        } else{
          final index = i+j*numCompX; 
          final value = decodeAC(
          decode83(blurHash, 4 + index * 2, (4 + index * 2) + 2),
          maxAc,
          );
          components[j][i] = value;
        }
      }
    }

    this.components = components;
    this.punch(punch);
    var threshold = 0.3;
    this.isDark = isAverageDark(threshold);
    this.isLeftEdgeDark = isDarkAtX(0, threshold);
    this.isRightEdgeDark = isDarkAtX(numCompX-1, threshold);
    this.isTopEdgeDark = isDarkAtY(0, threshold);
    this.isBottomEdgeDark = isDarkAtY(numCompY-1, threshold);
    this.isTopLeftCornerDark = isDarkAtPos(0, 0, threshold);
    this.isTopRightCornerDark = isDarkAtPos(numCompX-1, 0, threshold);
    this.isBottomLeftCornerDark = isDarkAtPos(0, numCompY-1, threshold);
    this.isBottomRightCornerDark = isDarkAtPos(numCompX-1, numCompY-1, threshold);
  }

  /// Decodes a [blurHash] to raw pixels in RGBA32 format with specified [width] and
  /// [height]. Both [width] and [height] must not be null and greater than 0. It is
  /// recommended to keep the [width] and [height] small and let the UI layer handle
  /// upscaling for better performance.
  Uint8List toBitmap(width,height){
    assert(width != null && width > 0);
    assert(height != null && height > 0);
    Uint8List image = _transform(width, height, numCompX, numCompY, components);
    _RGBA32BitmapHeader header = _RGBA32BitmapHeader(image.length, width, height);
    return header.appendContent(image);
  }

  /// Encodes an image to a BlurHash string
  ///
  /// The format of the given [data] array is expected to be raw pixels in RGBA32 format -
  /// without any additional image headers. The [width] and [height] are the dimensions of
  /// the given image. Parameters [numCompX] and [numCompY] are the components of the
  /// BlurHash. Both parameters must lie between 1 and 9.
  ///
  /// Throws [BlurHashEncodeException] when [numCompX] and [numCompY] do not lie within the
  /// expected range. Also throws [BlurHashEncodeException] when the [data] array is not in
  /// the expected RGBA32 format.

  BlurHash.fromImage(
  Uint8List data,
  int width,
  int height, {
  int numCompX = 4,
  int numpCompY = 3,
  }) {
    if (numCompX < 1 || numCompX > 9 || numpCompY < 1 || numCompX > 9) {
      throw BlurHashEncodeException(
        message: "BlurHash components must lie between 1 and 9.",
      );
    }

    if (width * height * 4 != data.length) {
      throw BlurHashEncodeException(
        message: "The width and height must match the data array."
            "The expected format is RGBA32",
      );
    }
    final factors = List<Color>(numCompX * numpCompY);
    int i = 0;
    for (var y = 0; y < numpCompY; ++y) {
      for (var x = 0; x < numCompX; ++x) {
        final normalisation = (x == 0 && y == 0) ? 1.0 : 2.0;
        final basisFunc = (int i, int j) {
          return normalisation *
              cos((pi * x * i) / width) *
              cos((pi * y * j) / height);
        };
        factors[i++] = _multiplyBasisFunction(data, width, height, basisFunc);
      }
    }

    final dc = factors.first;
    final ac = factors.skip(1).toList();

    final blurHash = StringBuffer();
    final sizeFlag = (numCompX - 1) + (numpCompY - 1) * 9;
    blurHash.write(encode83(sizeFlag, 1));

    var maxVal = 1.0;
    if (ac.isNotEmpty) {
      final maxElem = (Color c) => max(c.r.abs(), max(c.g.abs(), c.b.abs()));
      final actualMax = ac.map(maxElem).reduce(max);
      final quantisedMax = max(0, min(82, (actualMax * 166.0 - 0.5).floor()));
      maxVal = (quantisedMax + 1.0) / 166.0;
      blurHash.write(encode83(quantisedMax, 1));
    } else {
      blurHash.write(encode83(0, 1));
    }

    blurHash.write(encode83(encodeDC(dc), 4));
    for (final factor in ac) {
      blurHash.write(encode83(encodeAC(factor, maxVal), 2));
    }

    BlurHash createdBlurHash = BlurHash.fromString(blurHash.toString());
    this.components = createdBlurHash.components;
    this.blurHashString = blurHash.toString();
    this.numCompX = createdBlurHash.numCompX;
    this.numCompY = createdBlurHash.numCompY;

    this.isDark = createdBlurHash.isDark;
    this.isLeftEdgeDark = createdBlurHash.isLeftEdgeDark;
    this.isRightEdgeDark = createdBlurHash.isRightEdgeDark;
    this.isTopEdgeDark = createdBlurHash.isTopEdgeDark;
    this.isBottomEdgeDark = createdBlurHash.isBottomEdgeDark;
    this.isTopLeftCornerDark = createdBlurHash.isTopLeftCornerDark;
    this.isTopRightCornerDark = createdBlurHash.isTopRightCornerDark;
    this.isBottomLeftCornerDark = createdBlurHash.isBottomLeftCornerDark;
    this.isBottomRightCornerDark = createdBlurHash.isBottomRightCornerDark;
  }

  String toHash(){
    return this.blurHashString;
  }

  ///Checks if certain spots of a picture are Dark
  bool isAverageDark(threshold){
    Color color = averageLinearRGB();
    return checkDarkness(color, threshold);
  }

  bool isDarkAtX(x, threshold){
    Color color = linearRGBAtX(x);
    return checkDarkness(color, threshold);
  }

  bool isDarkAtY(x, threshold){
    Color color = linearRGBAtY(x);
    return checkDarkness(color, threshold);
  }
  
  bool isDarkAtPos(x, y, threshold){
    Color color = linearRGBAtPos(x,y);
    return checkDarkness(color, threshold);
  }

  bool isDarkFromUpperRightToLowerLeft(upperLeftX,upperLeftY,lowerRightX,lowerRightY,threshold){
    Color color = linearRGBFromUpperLeftToLowerRight(upperLeftX, upperLeftY, lowerRightX, lowerRightY);
    return checkDarkness(color,threshold);
  }

  bool checkDarkness(color, threshold){
    return color.r * 0.299 + color.g * 0.587 + color.b * 0.114 < threshold;
  }

/// Calculates LinearRGB Values at certain spots
  Color averageLinearRGB(){
    return components[0][0];
  }

  Color linearRGBAtX(x){
    if(x >= numCompX){
      throw ArgumentError(ArgumentError);
    }

    Color sum = Color(0,0,0);
    int i = 0;
    for(final component in components[0]){
      sum += component * cos(pi * i++ * x);
    }
    return sum;
  }

  Color linearRGBAtY(y){
    if(y >= numCompY){
      throw ArgumentError(ArgumentError);
    }

    Color sum = Color(0,0,0);
    int i = 0;
    for(final horizontalComponents in components){
      sum += horizontalComponents[0] * cos(pi * i++ * y);
    }
    return sum;
  }

  Color linearRGBAtPos(x,y){
    if(y >= numCompY || x >= numCompX){
      throw ArgumentError(ArgumentError);
    }
    Color sum = Color(0,0,0);
    for(var j = 0; j < numCompY; j++){
      for(var i = 0; i <numCompX; i++){
        sum += components[j][i] * cos(pi * i * x) * cos(pi * j * y);
      }
    }
    return sum;
  }
  Color linearRGBFromUpperLeftToLowerRight(upperLeftX,upperLeftY,lowerRightX,lowerRightY){
    if(upperLeftY >= numCompY || lowerRightY >= numCompY || upperLeftX >= numCompX || lowerRightX >= numCompX){
      throw ArgumentError(ArgumentError);
    }
    Color sum = Color(0,0,0);
    for(var j = 0; j < numCompY; j++){
      for(var i = 0; i < numCompX; i++){
        final horizontalAverage = i==0 ? 1 : ((sin(pi * i * lowerRightX) - sin(pi * i * upperLeftX))/(i*pi*(lowerRightX-upperLeftX)));
        final verticalAverage = j==0 ? 1 : ((sin(pi * j * lowerRightY) - sin(pi * j * upperLeftY))/(j*pi*(lowerRightY-upperLeftY)));
        sum += components[j][i] * horizontalAverage * verticalAverage;
      }
    }
    return sum;
  }
}

Uint8List _transform(
  int width,
  int height,
  int numCompX,
  int numCompY,
  List<List<Color>> components,
) {
  final pixels = List<int>(width * height * 4);

  int pixel = 0;
  for (var y = 0; y < height; ++y) {
    for (var x = 0; x < width; ++x) {
      var r = 0.0;
      var g = 0.0;
      var b = 0.0;

      for (var j = 0; j < numCompY; ++j) {
        for (var i = 0; i < numCompX; ++i) {
          final basis = (cos(pi * x * i / width) * cos(pi * y * j / height));
          final color = components[j][i];
          r += color.r * basis;
          g += color.g * basis;
          b += color.b * basis;
        }
      }

      pixels[pixel++] = linearTosRGB(r);
      pixels[pixel++] = linearTosRGB(g);
      pixels[pixel++] = linearTosRGB(b);
      pixels[pixel++] = 255;
    }
  }

  return Uint8List.fromList(pixels);
}

Color _multiplyBasisFunction(
  Uint8List pixels,
  int width,
  int height,
  double basisFunction(int i, int j),
) {
  var r = 0.0;
  var g = 0.0;
  var b = 0.0;

  final bytesPerRow = width * 4;

  for (var x = 0; x < width; ++x) {
    for (var y = 0; y < height; ++y) {
      final basis = basisFunction(x, y);
      r += basis * sRGBtoLinear(pixels[4 * x + 0 + y * bytesPerRow]);
      g += basis * sRGBtoLinear(pixels[4 * x + 1 + y * bytesPerRow]);
      b += basis * sRGBtoLinear(pixels[4 * x + 2 + y * bytesPerRow]);
    }
  }

  final scale = 1.0 / (width * height);
  return Color(r * scale, g * scale, b * scale);
}

const int _RGBA32HeaderSize = 122;

class _RGBA32BitmapHeader {
  final int contentSize;
  Uint8List headerIntList;

  /// Create a new RGBA32 header
  _RGBA32BitmapHeader(this.contentSize, int width, int height) {
    final int fileLength = contentSize + _RGBA32HeaderSize;
    headerIntList = Uint8List(fileLength);
    headerIntList.buffer.asByteData()
      ..setUint8(0x0, 0x42)
      ..setUint8(0x1, 0x4d)
      ..setInt32(0x2, fileLength, Endian.little)
      ..setInt32(0xa, _RGBA32HeaderSize, Endian.little)
      ..setUint32(0xe, 108, Endian.little)
      ..setUint32(0x12, width, Endian.little)
      ..setUint32(0x16, -height, Endian.little)
      ..setUint16(0x1a, 1, Endian.little)
      ..setUint32(0x1c, 32, Endian.little)
      ..setUint32(0x1e, 3, Endian.little)
      ..setUint32(0x22, contentSize, Endian.little)
      ..setUint32(0x36, 0x000000ff, Endian.little)
      ..setUint32(0x3a, 0x0000ff00, Endian.little)
      ..setUint32(0x3e, 0x00ff0000, Endian.little)
      ..setUint32(0x42, 0xff000000, Endian.little);
  }

  Uint8List appendContent(Uint8List contentIntList) {
    headerIntList.setRange(
      _RGBA32HeaderSize,
      contentSize + _RGBA32HeaderSize,
      contentIntList,
    );

    return headerIntList;
  }
}

