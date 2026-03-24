import 'dart:html' as html;
import './platform_file_helper_stub.dart';

class WebFileHelper implements PlatformFileHelper {
  @override
  Future<void> saveAndDownloadFile(
    String fileName,
    List<int> bytes, {
    String? mimeType,
  }) async {
    final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}

PlatformFileHelper getHelper() => WebFileHelper();
