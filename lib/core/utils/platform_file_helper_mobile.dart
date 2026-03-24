import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_pharmacy_system/core/utils/platform_file_helper_stub.dart';

class MobileFileHelper implements PlatformFileHelper {
  @override
  Future<void> saveAndDownloadFile(
    String fileName,
    List<int> bytes, {
    String? mimeType,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path, mimeType: mimeType),
    ], subject: fileName);
  }
}

PlatformFileHelper getHelper() => MobileFileHelper();
