import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:olt_inventory/constants/app_constants.dart';
import 'package:olt_inventory/services/supabase_service.dart';

class StorageService {
  StorageService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<String> uploadXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final extension = _resolveExtension(file);
    return uploadBytes(bytes, extension: extension);
  }

  Future<String> uploadBytes(
    Uint8List bytes, {
    required String extension,
  }) async {
    final normalizedExtension = extension.toLowerCase();
    final fileName = '${_uuid.v4()}.$normalizedExtension';
    final path = 'items/$fileName';

    await _client.storage.from(AppConstants.storageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentType(normalizedExtension),
            upsert: true,
          ),
        );

    return _client.storage.from(AppConstants.storageBucket).getPublicUrl(path);
  }

  String _resolveExtension(XFile file) {
    final pathExt = file.path.split('.').last.toLowerCase();
    if (pathExt.isNotEmpty &&
        pathExt != file.path.toLowerCase() &&
        pathExt.length <= 5) {
      return pathExt;
    }

    final nameExt = file.name.split('.').last.toLowerCase();
    if (nameExt.isNotEmpty &&
        nameExt != file.name.toLowerCase() &&
        nameExt.length <= 5) {
      return nameExt;
    }

    return 'jpg';
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> deleteImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    final path = _extractPath(imageUrl);
    if (path == null) return;

    try {
      await _client.storage.from(AppConstants.storageBucket).remove([path]);
    } on StorageException {
      // Ignore missing files during cleanup.
    }
  }

  String? _extractPath(String url) {
    final publicMarker =
        '/storage/v1/object/public/${AppConstants.storageBucket}/';
    final publicIndex = url.indexOf(publicMarker);
    if (publicIndex != -1) {
      return url.substring(publicIndex + publicMarker.length);
    }

    final privateMarker = '/storage/v1/object/${AppConstants.storageBucket}/';
    final privateIndex = url.indexOf(privateMarker);
    if (privateIndex != -1) {
      return url.substring(privateIndex + privateMarker.length);
    }

    return null;
  }

  static String formatStorageError(Object error) {
    if (error is StorageException) {
      return error.message;
    }
    return error.toString();
  }
}
