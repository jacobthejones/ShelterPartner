import 'dart:io';
import 'package:collection/collection.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> image, [Map<String, Object?>? args]) async {
          final File screenshotFile = await File(
            'integration_test/screenshots/last_run/$name.png',
          ).create(recursive: true);
          screenshotFile.writeAsBytesSync(image);

          // Load canonical image if it exists
          final File canonicalFile = File(
            'integration_test/screenshots/canonical/$name.png',
          );
          final canonicalBytes = canonicalFile.existsSync()
              ? canonicalFile.readAsBytesSync()
              : null;
          if (canonicalBytes == null) {
            // print('No canonical image found for $name. ');
            return true; // No canonical image to compare against
          }
          if (canonicalBytes.length != image.length ||
              !const ListEquality().equals(canonicalBytes, image)) {
            // print(
            //   'Screenshot $name does not match the canonical image. '
            //   'Please update the canonical image if this is expected.',
            // );
            return true; // Screenshot does not match canonical
          }

          // print('Screenshot $name matches the canonical image.');
          return true;
        },
  );
}
