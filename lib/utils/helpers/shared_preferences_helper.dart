import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static Future<void> saveStringToSP(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> saveBoolToSP(String key, {required bool value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<void> saveIntToSP(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  static Future<void> saveDoubleToSP(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  static Future<void> saveStringListToSP(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  static Future<String> readStringFromSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key) ?? '';
    return value;
  }

  static Future<bool?> readBoolFromSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(key);
    return value;
  }

  static Future<int> readIntFromSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(key) ?? 0;
    return value;
  }

  static Future<List<String>> readStringListFromSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getStringList(key) ?? [];
    return value;
  }

  static Future<bool> removeValueFromSP(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    return true;
  }
}
