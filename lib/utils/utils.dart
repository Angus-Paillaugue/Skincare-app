import 'package:skincare/models/time.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class Utils {
  static String formatInterval(int days, SkincareTime time) {
    if (days <= 1) return time == SkincareTime.morning ? 'Daily' : "Every Night";
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

  static Future<String?> pickAndSaveImage({ ImageSource source = ImageSource.camera, CameraDevice preferredCameraDevice = CameraDevice.rear,
   }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, preferredCameraDevice: preferredCameraDevice,
    );

    if (pickedFile == null) return null;

    final appDir = await getApplicationDocumentsDirectory();

    final fileName = p.basename(pickedFile.path);
    final localImage = File('${appDir.path}/$fileName');

    final savedImage = await File(pickedFile.path).copy(localImage.path);

    return savedImage.path;
  }

}
