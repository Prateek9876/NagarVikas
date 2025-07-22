import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionUtil {
  static const int _defaultQuality = 80;
  static const int _maxWidth = 1920;
  static const int _maxHeight = 1080;
  static const int _maxFileSizeKB = 500;

  static Future<File?> compressImage(
    File imageFile, {
    int quality = _defaultQuality,
    int maxWidth = _maxWidth,
    int maxHeight = _maxHeight,
    int maxFileSizeKB = _maxFileSizeKB,
  }) async {
    try {
      final originalSize = await imageFile.length();
      final originalSizeKB = originalSize / 1024;

      print('Original image size: ${originalSizeKB.toStringAsFixed(2)} KB');

      if (originalSizeKB <= maxFileSizeKB && quality == _defaultQuality) {
        print('Image already optimized, returning original');
        return imageFile;
      }

      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      var compressedFile = await _performCompression(
        imageFile,
        targetPath,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (compressedFile == null) {
        print('Initial compression failed');
        return imageFile;
      }

      var compressedSize = await compressedFile.length();
      var compressedSizeKB = compressedSize / 1024;
      var currentQuality = quality;

      print(
          'First compression result: ${compressedSizeKB.toStringAsFixed(2)} KB');

      while (compressedSizeKB > maxFileSizeKB && currentQuality > 20) {
        currentQuality = (currentQuality * 0.8).round();

        final newTargetPath = path.join(
          tempDir.path,
          'compressed_${DateTime.now().millisecondsSinceEpoch}_q$currentQuality.jpg',
        );

        final newCompressedFile = await _performCompression(
          imageFile,
          newTargetPath,
          quality: currentQuality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );

        if (newCompressedFile != null) {
          if (await compressedFile!.exists()) {
            await compressedFile.delete();
          }

          compressedFile = newCompressedFile;
          compressedSize = await compressedFile.length();
          compressedSizeKB = compressedSize / 1024;

          print(
              'Reduced quality to $currentQuality%, size: ${compressedSizeKB.toStringAsFixed(2)} KB');
        } else {
          break;
        }
      }

      final finalSizeKB = (await compressedFile!.length()) / 1024;
      final compressionRatio =
          ((originalSizeKB - finalSizeKB) / originalSizeKB * 100);

      print('Final compressed size: ${finalSizeKB.toStringAsFixed(2)} KB');
      print('Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');

      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return imageFile;
    }
  }

  static Future<File?> _performCompression(
    File imageFile,
    String targetPath, {
    required int quality,
    required int maxWidth,
    required int maxHeight,
  }) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: maxWidth ~/ 2,
        minHeight: maxHeight ~/ 2,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        return null;
      }

      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      print('Error in _performCompression: $e');
      return null;
    }
  }

  static Future<File?> compressImageWithCustomSize(
    File imageFile, {
    required int targetWidth,
    required int targetHeight,
    int quality = _defaultQuality,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'custom_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        return imageFile;
      }

      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      print('Error in compressImageWithCustomSize: $e');
      return imageFile;
    }
  }

  static Future<Map<String, dynamic>> getImageInfo(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      final fileSizeKB = fileSize / 1024;

      return {
        'fileSizeBytes': fileSize,
        'fileSizeKB': fileSizeKB,
        'fileSizeMB': fileSizeKB / 1024,
        'path': imageFile.path,
      };
    } catch (e) {
      print('Error getting image info: $e');
      return {};
    }
  }

  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file.path.contains('compressed_') && file.path.endsWith('.jpg')) {
          await file.delete();
        }
      }

      print('Cleaned up temporary compressed files');
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }
}
