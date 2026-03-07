import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Comprime imagens antes do upload para reduzir o tamanho sem perda visual
/// perceptível. Uma foto de câmera de ~8 MB fica ~300–600 KB.
class ImageCompressService {
  /// Largura/altura máxima após resize (mantém proporção).
  static const int _maxDimension = 1920;

  /// Qualidade JPEG: 85 é um bom equilíbrio entre tamanho e nitidez.
  static const int _quality = 85;

  /// Comprime [bytes] e retorna os bytes JPEG resultantes.
  /// Caso a compressão falhe por qualquer motivo, retorna os bytes originais.
  static Future<Uint8List> compress(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        quality: _quality,
        format: CompressFormat.jpeg,
      );
      // Só usa o resultado comprimido se for menor que o original.
      if (result.length < bytes.length) return result;
      return bytes;
    } catch (e) {
      debugPrint('ImageCompressService: falha ao comprimir, usando original. $e');
      return bytes;
    }
  }

  /// Retorna uma string legível com o tamanho em KB ou MB.
  static String formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
