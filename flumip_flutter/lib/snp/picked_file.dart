/// A file the user chose, described without naming anything web-only.
///
/// ⚠️ [handle] is the browser's own `File` object, carried as an opaque [Object]
/// on purpose. **Its bytes are never read into Dart.** A 1.5 GB VCF would not fit
/// comfortably in the heap, and does not need to: `XMLHttpRequest.send` accepts
/// the object directly and the browser streams it off the operating system's file
/// handle. Only `WebSnpTransport` ever casts it back.
///
/// Keeping this type free of `package:web` is what lets `SnpUploadController` and
/// its tests run on the Dart VM.
class PickedFile {
  const PickedFile({
    required this.name,
    required this.size,
    required this.handle,
  });

  final String name;
  final int size;
  final Object handle;

  @override
  String toString() => 'PickedFile($name, $size bytes)';
}
