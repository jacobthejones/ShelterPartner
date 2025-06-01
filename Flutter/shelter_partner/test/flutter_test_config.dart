import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A custom golden comparator that allows for a percentage of pixels to be different.
class FuzzyGoldenComparator extends LocalFileComparator {
  final double maxDiffPercent;

  FuzzyGoldenComparator(super.testFile, {this.maxDiffPercent = 2.0});

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenBytes = await File.fromUri(_resolve(golden)).readAsBytes();
    final img.Image? goldenImage = img.decodeImage(goldenBytes);
    final img.Image? testImage = img.decodeImage(imageBytes);
    if (goldenImage == null || testImage == null) {
      print('Could not decode images for comparison.');
      return false;
    }
    if (goldenImage.width != testImage.width ||
        goldenImage.height != testImage.height) {
      print('Image sizes do not match: '
          'expected \\${goldenImage.width}x\\${goldenImage.height}, '
          'found \\${testImage.width}x\\${testImage.height}.');
      return false;
    }
    int diffPixels = 0;
    for (int y = 0; y < goldenImage.height; y++) {
      for (int x = 0; x < goldenImage.width; x++) {
        if (goldenImage.getPixel(x, y) != testImage.getPixel(x, y)) {
          diffPixels++;
        }
      }
    }
    final totalPixels = goldenImage.width * goldenImage.height;
    final diffPercent = 100.0 * diffPixels / totalPixels;
    if (diffPercent > maxDiffPercent) {
      print(
          'Images differ by \\${diffPercent.toStringAsFixed(2)}% (allowed: $maxDiffPercent%)');
      return false;
    }
    return true;
  }

  Uri _resolve(Uri uri) => uri.isAbsolute ? uri : this.basedir.resolveUri(uri);

  /// Returns the resolved URI for the golden file.
  @override
  Uri getTestUri(Uri uri, [int? version]) {
    return Uri.parse(Uri.decodeFull('$uri')).isAbsolute
        ? uri
        : Uri.parse(Uri.decodeFull('$uri')).replace(scheme: 'file');
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final testDir = Directory.current.uri;
  goldenFileComparator = FuzzyGoldenComparator(testDir, maxDiffPercent: 1.0);
  await testMain();
}
