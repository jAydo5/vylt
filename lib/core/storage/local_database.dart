class LocalDatabase {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Later:
    // - Open Hive / Drift / Isar
    // - Run migrations
    // - Handle encryption keys

    await Future.delayed(const Duration(milliseconds: 200));
    _initialized = true;
  }
}
