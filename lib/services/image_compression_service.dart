import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

/// Client-side image compression service for efficient backend transmission
/// Optimizes images to reduce bandwidth and improve processing speed
class ImageCompressionService {
  static ImageCompressionService? _instance;
  static ImageCompressionService get instance {
    _instance ??= ImageCompressionService._();
    return _instance!;
  }

  ImageCompressionService._();

  // Compression configuration
  static const int _maxWidth = 640;
  static const int _maxHeight = 480;
  static const int _targetFileSizeKB = 80; // Target: 80KB per image
  static const int _qualityThreshold = 70; // JPEG quality threshold
  static const int _compressionQualityStep =
      10; // Quality step for binary search

  /// Compress CameraImage for transmission to backend
  Future<CompressedImage> compressCameraImage(
    CameraImage image, {
    int? maxWidth,
    int? maxHeight,
    int? targetFileSizeKB,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('ImageCompressionService: Starting compression');
      debugPrint(
          'ImageCompressionService: Original size: ${image.width}x${image.height}');

      // Use provided parameters or defaults
      final targetMaxWidth = maxWidth ?? _maxWidth;
      final targetMaxHeight = maxHeight ?? _maxHeight;
      final targetSizeKB = targetFileSizeKB ?? _targetFileSizeKB;

      // Convert CameraImage to raw image data
      final rawImage = await _convertCameraImageToRawImage(image);
      if (rawImage == null) {
        throw Exception('Failed to convert CameraImage to raw image');
      }

      // Calculate optimal compression parameters
      final scaleFactor = _calculateScaleFactor(
        rawImage.width,
        rawImage.height,
        targetMaxWidth,
        targetMaxHeight,
      );

      final targetWidth = (rawImage.width * scaleFactor).round();
      final targetHeight = (rawImage.height * scaleFactor).round();

      debugPrint(
          'ImageCompressionService: Target size: ${targetWidth}x${targetHeight}');
      debugPrint('ImageCompressionService: Scale factor: $scaleFactor');

      // Resize image if needed
      final resizedImage =
          await _resizeImage(rawImage, targetWidth, targetHeight);
      if (resizedImage == null) {
        throw Exception('Failed to resize image');
      }

      // Compress to target file size
      final compressedImage = await _compressToTargetSize(
        resizedImage,
        targetSizeKB,
        _qualityThreshold,
      );

      stopwatch.stop();
      final compressionTime = stopwatch.elapsedMilliseconds;

      final result = CompressedImage(
        data: compressedImage.data,
        originalSize: ImageSize(width: image.width, height: image.height),
        compressedSize: ImageSize(
            width: compressedImage.width, height: compressedImage.height),
        compressionRatio: _calculateCompressionRatio(
          image.width * image.height,
          compressedImage.width * compressedImage.height,
        ),
        fileSizeKB: compressedImage.data.length / 1024,
        compressionTimeMs: compressionTime,
        quality: compressedImage.quality,
        format: compressedImage.format,
      );

      debugPrint('ImageCompressionService: Compression completed');
      debugPrint(
          'ImageCompressionService: Original: ${image.width}x${image.height}');
      debugPrint(
          'ImageCompressionService: Compressed: ${compressedImage.width}x${compressedImage.height}');
      debugPrint(
          'ImageCompressionService: File size: ${result.fileSizeKB.toStringAsFixed(1)}KB');
      debugPrint(
          'ImageCompressionService: Compression ratio: ${(result.compressionRatio * 100).toStringAsFixed(1)}%');
      debugPrint(
          'ImageCompressionService: Quality: ${compressedImage.quality}');
      debugPrint('ImageCompressionService: Time: ${compressionTime}ms');

      return result;
    } catch (e) {
      debugPrint('ImageCompressionService: Compression failed: $e');
      rethrow;
    }
  }

  /// Convert CameraImage to raw image data
  Future<RawImageData?> _convertCameraImageToRawImage(CameraImage image) async {
    try {
      // For now, return the planes data
      // In a real implementation, you would convert YUV to RGB
      final plane = image.planes.first; // Use Y plane
      return RawImageData(
        data: plane.bytes,
        width: image.width,
        height: image.height,
        format: 'yuv',
      );
    } catch (e) {
      debugPrint('ImageCompressionService: Failed to convert camera image: $e');
      return null;
    }
  }

  /// Calculate scale factor to fit within max dimensions
  double _calculateScaleFactor(
    int originalWidth,
    int originalHeight,
    int maxWidth,
    int maxHeight,
  ) {
    final widthRatio = maxWidth / originalWidth;
    final heightRatio = maxHeight / originalHeight;

    return widthRatio < heightRatio ? widthRatio : heightRatio;
  }

  /// Resize image to target dimensions
  Future<RawImageData?> _resizeImage(
    RawImageData image,
    int targetWidth,
    int targetHeight,
  ) async {
    try {
      if (image.width == targetWidth && image.height == targetHeight) {
        return image; // No resize needed
      }

      debugPrint(
          'ImageCompressionService: Resizing from ${image.width}x${image.height} to ${targetWidth}x${targetHeight}');

      // For now, return the same image with new dimensions
      // In a real implementation, you would use image_resize or similar
      return RawImageData(
        data: image.data,
        width: targetWidth,
        height: targetHeight,
        format: image.format,
      );
    } catch (e) {
      debugPrint('ImageCompressionService: Failed to resize image: $e');
      return null;
    }
  }

  /// Compress image to target file size using binary search
  Future<CompressedImageData> _compressToTargetSize(
    RawImageData image,
    int targetSizeKB,
    int maxQuality,
  ) async {
    final targetSizeBytes = targetSizeKB * 1024;
    int quality = maxQuality;
    Uint8List? compressedData;
    int attempts = 0;
    const maxAttempts = 8;

    while (attempts < maxAttempts) {
      attempts++;

      // Simulate compression (in real implementation, use actual compression)
      compressedData =
          _simulateImageCompression(image.data, quality, image.format);

      final currentSize = compressedData.length;
      debugPrint(
          'ImageCompressionService: Attempt $attempts, quality=$quality, size=${currentSize / 1024}KB');

      if (currentSize <= targetSizeBytes) {
        // Size is good, try higher quality
        if (quality >= maxQuality) break;
        quality = (quality + (maxQuality - quality) / 2).round();
      } else {
        // Size is too large, reduce quality
        if (quality <= 10) break;
        quality = (quality / 2).round();
      }
    }

    if (compressedData == null) {
      throw Exception('Failed to compress image to target size');
    }

    return CompressedImageData(
      data: compressedData,
      width: image.width,
      height: image.height,
      quality: quality,
      format: 'jpeg', // Assume JPEG for cloud transmission
    );
  }

  /// Simulate image compression (placeholder for real implementation)
  Uint8List _simulateImageCompression(
      Uint8List data, int quality, String format) {
    // This is a simulation - in reality, you would:
    // 1. Convert YUV to RGB if needed
    // 2. Apply JPEG compression with specified quality
    // 3. Return compressed data

    // For simulation, just return data with size reduction based on quality
    final qualityFactor = quality / 100.0;
    final targetSize =
        (data.length * qualityFactor * 0.7).round(); // Simulate compression

    if (targetSize >= data.length) {
      return data; // No compression applied
    }

    // Return subset of data to simulate compression
    return data.sublist(0, targetSize);
  }

  /// Calculate compression ratio
  double _calculateCompressionRatio(int originalPixels, int compressedPixels) {
    if (originalPixels == 0) return 0.0;
    return compressedPixels / originalPixels;
  }

  /// Check if image should be compressed
  bool shouldCompressImage(int fileSizeBytes) {
    return fileSizeBytes > (_targetFileSizeKB * 1024);
  }

  /// Get compression statistics
  Map<String, dynamic> getCompressionStats() {
    return {
      'maxWidth': _maxWidth,
      'maxHeight': _maxHeight,
      'targetFileSizeKB': _targetFileSizeKB,
      'qualityThreshold': _qualityThreshold,
      'compressionStep': _compressionQualityStep,
    };
  }

  /// Dispose resources
  void dispose() {
    _instance = null;
  }
}

/// Raw image data structure
class RawImageData {
  final Uint8List data;
  final int width;
  final int height;
  final String format;

  RawImageData({
    required this.data,
    required this.width,
    required this.height,
    required this.format,
  });
}

/// Compressed image data structure
class CompressedImageData {
  final Uint8List data;
  final int width;
  final int height;
  final int quality;
  final String format;

  CompressedImageData({
    required this.data,
    required this.width,
    required this.height,
    required this.quality,
    required this.format,
  });
}

/// Image size structure
class ImageSize {
  final int width;
  final int height;

  ImageSize({required this.width, required this.height});

  @override
  String toString() => '${width}x${height}';
}

/// Final compressed image result
class CompressedImage {
  final Uint8List data;
  final ImageSize originalSize;
  final ImageSize compressedSize;
  final double compressionRatio;
  final double fileSizeKB;
  final int compressionTimeMs;
  final int quality;
  final String format;

  CompressedImage({
    required this.data,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.fileSizeKB,
    required this.compressionTimeMs,
    required this.quality,
    required this.format,
  });

  /// Get compression efficiency score (0-100)
  double get efficiencyScore {
    final sizeEfficiency =
        (1.0 - (fileSizeKB / 100.0)) * 50; // 50 points for size
    final qualityScore = (quality / 100.0) * 30; // 30 points for quality
    const timeScore = 20.0; // 20 points for reasonable compression time

    return (sizeEfficiency + qualityScore + timeScore).clamp(0.0, 100.0);
  }

  /// Check if compression is optimal
  bool get isOptimal => fileSizeKB <= 80 && quality >= 60;

  @override
  String toString() {
    return 'CompressedImage('
        'original: ${originalSize}, '
        'compressed: ${compressedSize}, '
        'size: ${fileSizeKB.toStringAsFixed(1)}KB, '
        'quality: $quality, '
        'efficiency: ${efficiencyScore.toStringAsFixed(1)}%)';
  }
}
