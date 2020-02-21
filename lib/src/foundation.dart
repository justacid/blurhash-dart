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
    signPow2((r - 9.0) / 9.0) * maxVal,
    signPow2((g - 9.0) / 9.0) * maxVal,
    signPow2((b - 9.0) / 9.0) * maxVal,
  );
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

double signPow2(double value) {
  return pow(value.abs(), 2.0) * value.sign;
}
