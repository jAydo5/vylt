class ConsentRepository {
  ConsentRepository._internal();

  static final ConsentRepository instance =
      ConsentRepository._internal();

  static bool _initialized = false;
  bool _hasAcceptedConsent = false;

  static Future<void> init() async {
    if (_initialized) return;

    // Later:
    // - Load from secure storage
    // - Support GDPR audit trail
    await Future.delayed(const Duration(milliseconds: 200));

    _initialized = true;
  }

  Future<bool> hasAcceptedConsent() async {
    return _hasAcceptedConsent;
  }

  Future<void> acceptConsent() async {
    _hasAcceptedConsent = true;
  }

  Future<void> revokeConsent() async {
    _hasAcceptedConsent = false;
  }
}
