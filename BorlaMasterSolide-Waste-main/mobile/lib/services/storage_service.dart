import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final supabaseClient = Supabase.instance.client;
final _uuid = const Uuid();

class StorageService {
  /// ✅ Uploads user avatar to Supabase Storage
  static Future<String?> uploadAvatar(String userId, File avatarFile) async {
    try {
      final fileExt = avatarFile.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExt';
      final filePath = 'avatars/$userId/$fileName';

      // Upload file to Supabase Storage
      await supabaseClient.storage.from('avatars').upload(filePath, avatarFile);

      // Get public URL for the uploaded avatar
      final publicUrl =
          supabaseClient.storage.from('avatars').getPublicUrl(filePath);

      return publicUrl;
    } on StorageException catch (e) {
      print('Storage error: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error uploading avatar: $e');
      return null;
    }
  }

  /// 🗑️ Optional: Delete avatar by file path
  static Future<void> deleteAvatar(String filePath) async {
    try {
      await supabaseClient.storage.from('avatars').remove([filePath]);
    } catch (e) {
      print('Error deleting avatar: $e');
    }
  }
}