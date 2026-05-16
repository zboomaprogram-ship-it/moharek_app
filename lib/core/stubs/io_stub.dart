class File {
  final String path;
  File(this.path);
  Future<bool> exists() async => false;
  Future<void> delete() async {}
}
