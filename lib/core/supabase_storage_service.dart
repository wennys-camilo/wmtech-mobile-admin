import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';

/// Serviço de upload de imagens para o Supabase Storage.
/// Bucket: product-images. Path: {productId}/{uuid}.{ext}
class SupabaseStorageService {
  static const String bucket = 'product-images';

  final SupabaseClient? _client;
  final Uuid _uuid = const Uuid();

  SupabaseStorageService([SupabaseClient? client])
    : _client = client ?? (AppConfig.hasSupabase ? Supabase.instance.client : null);

  bool get isAvailable => _client != null;

  /// Faz upload de um arquivo para product-images/{productId}/{uuid}.ext
  /// Retorna a URL pública ou null em caso de falha.
  Future<String?> uploadProductImage(String productId, XFile file) async {
    if (_client == null) return null;
    final bytes = await file.readAsBytes();
    final name = file.name;
    final ext = name.contains('.') ? name.split('.').last : 'jpg';
    if (ext.length > 4) return null;
    final path = '$productId/${_uuid.v4()}.$ext';
    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = _client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (error) {
      debugPrint('Error uploading product image: $error');
      return null;
    }
  }

  /// Extrai o path no bucket a partir da URL pública.
  /// URL esperada: .../storage/v1/object/public/product-images/{path}
  static String? pathFromPublicUrl(String publicUrl) {
    const prefix = '/object/public/$bucket/';
    final i = publicUrl.indexOf(prefix);
    if (i == -1) return null;
    return publicUrl.substring(i + prefix.length);
  }

  /// Remove uma imagem do bucket usando a URL pública retornada no upload.
  /// Retorna true se a remoção foi feita (ou cliente indisponível), false em erro.
  Future<bool> deleteProductImageByUrl(String imageUrl) async {
    if (_client == null) return true;
    final path = pathFromPublicUrl(imageUrl);
    if (path == null || path.isEmpty) {
      debugPrint('Could not extract storage path from URL: $imageUrl');
      return false;
    }
    try {
      await _client.storage.from(bucket).remove([path]);
      return true;
    } catch (error) {
      debugPrint('Error deleting product image: $error');
      return false;
    }
  }
}
