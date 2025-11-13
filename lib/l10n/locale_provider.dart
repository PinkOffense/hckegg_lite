import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  String _code;
  LocaleProvider([this._code = 'en']);

  String get code => _code;

  void setLocale(String code) {
    if (code == _code) return;
    _code = code;
    notifyListeners();
  }
}
