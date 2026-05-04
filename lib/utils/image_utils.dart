import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

class LetterboxResult {
  final Float32List tensor; // CHW planar [1,3,640,640]
  final double scale;
  final int padX;
  final int padY;
  const LetterboxResult({required this.tensor, required this.scale, required this.padX, required this.padY});
}

class ImageUtils {
  /// Convert CameraImage YUV420 to img.Image RGB
  static img.Image convertYUV420toRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image result = img.Image(width: width, height: height);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final int yVal = yBytes[yIndex] & 0xFF;
        final int uVal = (uBytes[uvIndex] & 0xFF) - 128;
        final int vVal = (vBytes[uvIndex] & 0xFF) - 128;

        int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
        int g = (yVal - 0.344136 * uVal - 0.714136 * vVal).round().clamp(0, 255);
        int b = (yVal + 1.772 * uVal).round().clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  /// Letterbox resize to targetSize x targetSize, returns CHW planar Float32List
  static LetterboxResult letterboxResize(img.Image image, int targetSize) {
    final double scaleW = targetSize / image.width;
    final double scaleH = targetSize / image.height;
    final double scale = scaleW < scaleH ? scaleW : scaleH;

    final int newW = (image.width * scale).round();
    final int newH = (image.height * scale).round();
    final int padX = (targetSize - newW) ~/ 2;
    final int padY = (targetSize - newH) ~/ 2;

    final img.Image resized = img.copyResize(image, width: newW, height: newH, interpolation: img.Interpolation.linear);

    // Create padded canvas filled with grey (114,114,114)
    final img.Image canvas = img.Image(width: targetSize, height: targetSize);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(canvas, resized, dstX: padX, dstY: padY);

    // Convert to BHWC Float32List (interleaved: RGBRGB...)
    final int pixelCount = targetSize * targetSize;
    final Float32List tensor = Float32List(3 * pixelCount);

    int idx = 0;
    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final pixel = canvas.getPixel(x, y);
        tensor[idx++] = pixel.r / 255.0;
        tensor[idx++] = pixel.g / 255.0;
        tensor[idx++] = pixel.b / 255.0;
      }
    }

    return LetterboxResult(tensor: tensor, scale: scale, padX: padX, padY: padY);
  }

  /// Rescale detected box back to original image dimensions
  static Rect rescaleBox(Rect box, double scale, int padX, int padY) {
    return Rect.fromLTRB(
      (box.left - padX) / scale,
      (box.top - padY) / scale,
      (box.right - padX) / scale,
      (box.bottom - padY) / scale,
    );
  }
}
