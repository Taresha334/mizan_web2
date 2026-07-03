// filepath: lib/core/services/upload_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart'; // Add uuid to your pubspec.yaml

class MizanUploadService {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Picks an image and returns the XFile.
  /// Separating this allows you to show a preview in the UI before uploading.
  Future<XFile?> pickReceipt() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compresses to ~200-500KB
        maxWidth: 1600, // Limits resolution for faster uploads
      );
      return image;
    } catch (e) {
      debugPrint("Mizan Picker Error: $e");
      return null;
    }
  }

  /// Takes an XFile and uploads it to Supabase
  Future<String?> uploadReceipt(XFile image) async {
    try {
      // 1. Generate a truly unique filename using UUID
      // This prevents two users from uploading 'receipt_123.jpg' at the same time
      final String uniqueId = const Uuid().v4();
      final String fileExtension = image.name.split('.').last.toLowerCase();
      final String fileName = 'receipt_$uniqueId.$fileExtension';
      final String path = 'receipts/$fileName';

      // 2. Read bytes (Standard approach for both Web and Mobile)
      final Uint8List bytes = await image.readAsBytes();

      // 3. Upload to the 'receipts' bucket
      // Ensure this bucket exists in your Supabase Dashboard
      await _supabase.storage
          .from('receipts')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${fileExtension == 'png' ? 'png' : 'jpeg'}',
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // 4. Generate the Public URL
      final String publicUrl = _supabase.storage
          .from('receipts')
          .getPublicUrl(path);

      debugPrint("✅ Mizan Upload Success: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("❌ Mizan Upload Error: $e");
      return null;
    }
  }
}
