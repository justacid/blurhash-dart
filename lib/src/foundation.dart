import 'dart:math';

/// ColorTriplet by default is used to encode colors in linear space.
/// If you need the color in sRGB see [ColorTripletExtensions.toRgb].
class ColorTriplet {
  /// Construct a new [ColorTriplet].
  const ColorTriplet(this.r, this.g, this.b);

  /// The red component of the color triplet.
  final double r;

  /// The green component of the color triplet.
  final double g;

  /// The blue component of the color triplet.
  final double b;

  /// Adds two [ColorTriplet] objects.
  ColorTriplet operator +(ColorTriplet other) =>
      ColorTriplet(r + other.r, g + other.g, b + other.b);

  /// Subtracts two [ColorTriplet] objects.
  ColorTriplet operator -(ColorTriplet other) =>
      ColorTriplet(r - other.r, g - other.g, b - other.b);

  /// Multiplies two [ColorTriplet] objects.
  ColorTriplet operator *(double scalar) =>
      ColorTriplet(r * scalar, g * scalar, b * scalar);

  /// Divides two [ColorTriplet] objects.
  ColorTriplet operator /(double scalar) =>
      ColorTriplet(r / scalar, g / scalar, b / scalar);

  @override
  String toString() => 'ColorTriplet($r, $g, $b)';
}

ColorTriplet decodeDc(int value) {
  final r = value >> 16;
  final g = (value >> 8) & 255;
  final b = value & 255;

  return ColorTriplet(
    sRgbToLinear(r),
    sRgbToLinear(g),
    sRgbToLinear(b),
  );
}

ColorTriplet decodeAc(int value, double maxVal) {
  final r = value / (19.0 * 19.0);
  final g = (value / 19.0) % 19.0;
  final b = value % 19.0;

  return ColorTriplet(
    signPow((r - 9.0) / 9.0, 2.0) * maxVal,
    signPow((g - 9.0) / 9.0, 2.0) * maxVal,
    signPow((b - 9.0) / 9.0, 2.0) * maxVal,
  );
}

int encodeDc(ColorTriplet color) {
  final r = linearTosRgb(color.r);
  final g = linearTosRgb(color.g);
  final b = linearTosRgb(color.b);
  return (r << 16) + (g << 8) + b;
}

int encodeAc(ColorTriplet color, double maxVal) {
  final r = max(0, min(18, signPow(color.r / maxVal, 0.5) * 9 + 9.5)).floor();
  final g = max(0, min(18, signPow(color.g / maxVal, 0.5) * 9 + 9.5)).floor();
  final b = max(0, min(18, signPow(color.b / maxVal, 0.5) * 9 + 9.5)).floor();
  return r * 19 * 19 + g * 19 + b;
}

double sRgbToLinear(int value) {
  final v = value / 255.0;
  if (v <= 0.04045) return v / 12.92;
  return pow((v + 0.055) / 1.055, 2.4).toDouble();
}

int linearTosRgb(double value) {
  final v = value.clamp(0.0, 1.0);
  if (v <= 0.0031308) return (v * 12.92 * 255.0 + 0.5).toInt();
  return ((1.055 * pow(v, 1.0 / 2.4) - 0.055) * 255.0 + 0.5).toInt();
}

double signPow(double value, double exp) {
  return pow(value.abs(), exp) * value.sign;
}
