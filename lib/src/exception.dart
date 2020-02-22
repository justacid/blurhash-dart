class BlurHashDecodeException implements Exception {
  BlurHashDecodeException({String message}) : message = message ?? "";
  final String message;
}

class BlurHashEncodeException implements Exception {
  BlurHashEncodeException({String message}) : message = message ?? "";
  final String message;
}
