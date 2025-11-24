import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final fileServiceProvider = Provider<FileService>((ref) => FileService());

class FileService {
  Future<File?> pickImage() async {
    // Request permissions first
    final status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      // Handle permission denied - in a real app, show a dialog or settings
      // For now, we'll try to pick anyway as some OS versions don't strictly need it for picker
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      // Handle error
      return null;
    }
  }
}
