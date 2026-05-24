import 'package:shared_preferences/shared_preferences.dart';
import 'key_value_store.dart';

/// SharedPreferences-backed [KeyValueStore]. Lives in core (infrastructure).
class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async =>
      _prefs.setString(key, value);

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async =>
      _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) async => _prefs.remove(key);
}
