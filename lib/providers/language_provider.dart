
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier{
  final SharedPreferences prefs;
  Locale _locale = Locale('en');
  Locale get locale => _locale;
  LanguageProvider(this.prefs){
    _loadSavedLanguage();
  }
  Future<void> _loadSavedLanguage() async {
    final code = prefs.getString('language_code');
    if(code != null){
      _locale = Locale(code);
      notifyListeners();
    }else {
      await prefs.setString('language_code', _locale.languageCode);
    }
  }
  Future<void> setLanguage (Locale locale) async {
    _locale = locale;
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }

}