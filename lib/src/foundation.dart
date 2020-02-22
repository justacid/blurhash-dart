import 'dart:math';

class Color {
  Color(this.r, this.g, this.b);

  final double r;
  final double g;
  final double b;
}

Color decodeDC(int value) {
  final r = value >> 16;
  final g = (value >> 8) & 255;
  final b = value & 255;

  return Color(
    sRGBtoLinear(r),
    sRGBtoLinear(g),
    sRGBtoLinear(b),
  );
}

Color decodeAC(int value, double maxVal) {
  final r = value / (19.0 * 19.0);
  final g = (value / 19.0) % 19.0;
  final b = value % 19.0;

  return Color(
    signPow((r - 9.0) / 9.0, 2.0) * maxVal,
    signPow((g - 9.0) / 9.0, 2.0) * maxVal,
    signPow((b - 9.0) / 9.0, 2.0) * maxVal,
  );
}

int encodeDC(Color color) {
  final r = linearTosRGB(color.r);
  final g = linearTosRGB(color.g);
  final b = linearTosRGB(color.b);
  return (r << 16) + (g << 8) + b;
}

int encodeAC(Color color, double maxVal) {
  final r = max(0, min(18, signPow(color.r / maxVal, 0.5) * 9 + 9.5)).floor();
  final g = max(0, min(18, signPow(color.g / maxVal, 0.5) * 9 + 9.5)).floor();
  final b = max(0, min(18, signPow(color.b / maxVal, 0.5) * 9 + 9.5)).floor();
  return r * 19 * 19 + g * 19 + b;
}

double sRGBtoLinear(int value) {
  final v = value / 255.0;
  if (v <= 0.04045) return v / 12.92;
  return pow((v + 0.055) / 1.055, 2.4);
}

int linearTosRGB(double value) {
  final v = value.clamp(0.0, 1.0);
  if (v <= 0.0031308) return (v * 12.92 * 255.0 + 0.5).toInt();
  return ((1.055 * pow(v, 1.0 / 2.4) - 0.055) * 255.0 + 0.5).toInt();
}

double signPow(double value, double exp) {
  return pow(value.abs(), exp) * value.sign;
}
