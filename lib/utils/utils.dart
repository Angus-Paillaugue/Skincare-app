import 'package:skincare/models/product.dart';
import 'package:skincare/models/routine.dart';
import 'package:skincare/models/time.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class Utils {
  static String formatInterval(int days, SkincareTime time) {
    if (time == SkincareTime.none) {
      return 'Never used';
    }
    if (days <= 1)
      return time == SkincareTime.morning ? 'Daily' : "Every Night";
    if (days == 7) return 'Weekly';
    if (days == 30 || days == 31) return 'Monthly';
    return 'every $days days';
  }

  static int toOpacity(double value) {
    // Map the value from 0.0-1.0 to 0-255
    if (value < 0) return 0;
    if (value > 1) return 255;
    return (value * 255).toInt();
  }

  static Future<String?> pickAndSaveImage({
    ImageSource source = ImageSource.camera,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      preferredCameraDevice: preferredCameraDevice,
    );

    if (pickedFile == null) return null;

    final appDir = await getApplicationDocumentsDirectory();

    final fileName = p.basename(pickedFile.path);
    final localImage = File('${appDir.path}/$fileName');

    final savedImage = await File(pickedFile.path).copy(localImage.path);

    return savedImage.path;
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isDue(
    Product product,
    SkincareTime time,
    List<Routine> morningRoutines,
    List<Routine> nightRoutines,
  ) {
    final now = DateTime.now().toUtc();
    final routine = time == SkincareTime.morning
        ? morningRoutines
        : nightRoutines;

    if (!routine.any(
      (r) => r.product == null ? r.product!.id == product.id : false,
    )) {
      return false; // Product not in routine
    }
    final lastUsed = routine
        .firstWhere(
          (r) => r.product == null
              ? false
              : r.product!.id == product.id && r.routine == time,
        )
        .lastUsed;

    return !isSameDay(lastUsed, now);
  }

  static Future<File> writeDownloadFile(String name, String contents) async {
    Directory? _directory = await getDownloadsDirectory();
    if (_directory == null) {
      throw Exception("Could not get downloads directory");
    }
    String filePath = p.join(_directory.path, name);
    File file = File(filePath);

    if (await file.exists()) {
      // If the file exists, delete it before writing the new data
      await file.delete();
    }

    file.writeAsStringSync(contents);
    return file;
  }
}
