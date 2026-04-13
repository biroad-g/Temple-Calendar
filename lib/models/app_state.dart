import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool _showRokuyo = true;
  int _currentNavIndex = 0;

  // 個別六曜ON/OFF（キー: 六曜名）
  final Map<String, bool> _rokuyoVisibility = {
    '大安': true,
    '友引': true,
    '先勝': true,
    '先負': true,
    '仏滅': true,
    '赤口': true,
  };

  bool get showRokuyo => _showRokuyo;
  int get currentNavIndex => _currentNavIndex;
  Map<String, bool> get rokuyoVisibility => Map.unmodifiable(_rokuyoVisibility);

  /// 指定した六曜が表示対象かどうか
  bool isRokuyoVisible(String rokuyo) {
    if (!_showRokuyo) return false;
    return _rokuyoVisibility[rokuyo] ?? true;
  }

  AppState() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showRokuyo = prefs.getBool('showRokuyo') ?? true;
    for (final key in _rokuyoVisibility.keys) {
      _rokuyoVisibility[key] = prefs.getBool('rokuyo_$key') ?? true;
    }
    notifyListeners();
  }

  Future<void> toggleRokuyo() async {
    _showRokuyo = !_showRokuyo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showRokuyo', _showRokuyo);
    notifyListeners();
  }

  Future<void> toggleIndividualRokuyo(String name) async {
    _rokuyoVisibility[name] = !(_rokuyoVisibility[name] ?? true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rokuyo_$name', _rokuyoVisibility[name]!);
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }
}
