import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  String _code;
  static const _key = 'locale_code';

  LocaleProvider([this._code = 'en']) {
    _loadFromPrefs();
  }

  String get code => _code;

  void setLocale(String code) {
    if (code == _code) return;
    _code = code;
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved != _code) {
      _code = saved;
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _code);
  }
}
