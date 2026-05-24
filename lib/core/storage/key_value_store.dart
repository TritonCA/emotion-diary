/// Abstraction over local persistence. Domain/data depend on this contract,
/// never on SharedPreferences directly (ARCH rule: no external SDK in domain).
abstract interface class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}
