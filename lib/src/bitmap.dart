import 'dart:typed_data';

Uint8List buildBitmap(Uint8List content, int width, int height) {
  final headerSize = 122;
  final length = content.length + headerSize;
  final headerData = Uint8List(length);

  final ByteData header = headerData.buffer.asByteData();
  header.setUint8(0x0, 0x42);
  header.setUint8(0x1, 0x4d);
  header.setInt32(0x2, length, Endian.little);
  header.setInt32(0xa, headerSize, Endian.little);
  header.setUint32(0xe, 108, Endian.little);
  header.setUint32(0x12, width, Endian.little);
  header.setUint32(0x16, -height, Endian.little);
  header.setUint16(0x1a, 1, Endian.little);
  header.setUint32(0x1c, 32, Endian.little);
  header.setUint32(0x1e, 3, Endian.little);
  header.setUint32(0x22, content.length, Endian.little);
  header.setUint32(0x36, 0x000000ff, Endian.little);
  header.setUint32(0x3a, 0x0000ff00, Endian.little);
  header.setUint32(0x3e, 0x00ff0000, Endian.little);
  header.setUint32(0x42, 0xff000000, Endian.little);

  headerData.setRange(headerSize, length, content);
  return headerData;
}
