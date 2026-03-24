abstract class PlatformFileHelper {
  Future<void> saveAndDownloadFile(
    String fileName,
    List<int> bytes, {
    String? mimeType,
  });
}

PlatformFileHelper getHelper() => throw UnsupportedError(
  'Cannot create a helper without platform implementation',
);
