# Temple Calendar coyomi — 完全再現プロンプト（最新版）

## アプリ概要

日本の仏教寺院向けFlutterアプリ。六曜カレンダー・年齢計算・法事計算を一体化した実務支援ツール。

- **アプリ名**: Temple Calendar coyomi
- **パッケージ名**: com.templecalendar.coyomi.calendar
- **バージョン**: 1.0.1+2
- **フレームワーク**: Flutter 3.x（Android・Web対応）
- **カラーテーマ**: ネイビー（#0D1B2A）× ゴールド（#D4AF37）

---

## 使用パッケージ（pubspec.yaml）

```yaml
name: temple_calendar
description: Temple Calendar coyomi - 寺院用カレンダーアプリ（六曜・年忌法要・法事計算）
version: 1.0.1+2

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  shared_preferences: 2.5.3
  provider: 6.1.5+1
  intl: 0.20.2
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
```

---

## ディレクトリ構成

```
lib/
├── main.dart
├── models/
│   └── app_state.dart
├── screens/
│   ├── calendar_screen.dart
│   ├── age_screen.dart
│   ├── memorial_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── rokuyo_service.dart
│   ├── japanese_calendar_service.dart
│   └── memorial_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── calendar_grid.dart
    └── wareki_date_picker.dart
```

---

## カラーパレット（lib/theme/app_theme.dart）

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color navyDark   = Color(0xFF0D1B2A);  // 背景
  static const Color navyMedium = Color(0xFF1B2A3E);  // カード背景
  static const Color navyLight  = Color(0xFF243B55);  // ボーダー・入力欄
  static const Color gold       = Color(0xFFD4AF37);  // メインアクセント
  static const Color goldLight  = Color(0xFFE8C96A);  // サブアクセント
  static const Color goldDark   = Color(0xFFB8960C);  // スイッチトラック
  static const Color white      = Color(0xFFFFFFFF);
  static const Color offWhite   = Color(0xFFF5F0E8);
  static const Color textLight  = Color(0xFFCCCCCC);
  static const Color textMuted  = Color(0xFF888888);
  static const Color red        = Color(0xFFE53935);  // 日曜・祝日
  static const Color blue       = Color(0xFF1E88E5);  // 土曜
  static const Color success    = Color(0xFF43A047);

  // 六曜カラー
  static const Color taian      = Color(0xFFD4AF37);  // 大安：金
  static const Color tomobiki   = Color(0xFF4CAF50);  // 友引：緑
  static const Color sensho     = Color(0xFF2196F3);  // 先勝：青
  static const Color senbu      = Color(0xFF9C27B0);  // 先負：紫
  static const Color butsumetsu = Color(0xFFE53935);  // 仏滅：赤
  static const Color shakko     = Color(0xFF795548);  // 赤口：茶

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navyDark,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: goldLight,
        surface: navyMedium,
        onPrimary: navyDark,
        onSecondary: navyDark,
        onSurface: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyMedium,
        foregroundColor: gold,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: navyMedium,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: gold, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: navyDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return gold;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return goldDark;
          return navyLight;
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navyMedium,
        selectedItemColor: gold,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: gold, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: white),
        bodyMedium: TextStyle(color: textLight),
        bodySmall: TextStyle(color: textMuted),
      ),
      dividerColor: navyLight,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navyLight,
        labelStyle: const TextStyle(color: gold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: navyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
      ),
    );
  }
}
```

---

## エントリポイント（lib/main.dart）

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'screens/calendar_screen.dart';
import 'screens/age_screen.dart';
import 'screens/memorial_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const TempleCalendarApp(),
    ),
  );
}

class TempleCalendarApp extends StatelessWidget {
  const TempleCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temple Calendar coyomi',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP')],
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    CalendarScreen(),
    AgeScreen(),
    MemorialScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.gold, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: AppTheme.navyMedium,
          selectedItemColor: AppTheme.gold,
          unselectedItemColor: AppTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'カレンダー'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '年齢計算'),
            BottomNavigationBarItem(icon: Icon(Icons.local_florist), label: '法事計算'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
          ],
        ),
      ),
    );
  }
}
```

---

## 状態管理（lib/models/app_state.dart）

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool _showRokuyo = true;
  int _currentNavIndex = 0;

  final Map<String, bool> _rokuyoVisibility = {
    '大安': true, '友引': true, '先勝': true,
    '先負': true, '仏滅': true, '赤口': true,
  };

  bool get showRokuyo => _showRokuyo;
  int get currentNavIndex => _currentNavIndex;
  Map<String, bool> get rokuyoVisibility => Map.unmodifiable(_rokuyoVisibility);

  bool isRokuyoVisible(String rokuyo) {
    if (!_showRokuyo) return false;
    return _rokuyoVisibility[rokuyo] ?? true;
  }

  AppState() { _loadPreferences(); }

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
```

---

## 六曜計算サービス（lib/services/rokuyo_service.dart）

旧暦ベースの天文算法で計算。Chapront式新月計算を使用。

```dart
class RokuyoService {
  static const List<String> rokuyoNames = ['先勝','友引','先負','仏滅','大安','赤口'];

  // 計算式：(旧暦月 + 旧暦日) % 6
  static int getRokuyoIndex(int lunarMonth, int lunarDay) =>
      (lunarMonth + lunarDay) % 6;

  static String getRokuyo(DateTime date) {
    final lunar = _toLunar(date);
    return rokuyoNames[getRokuyoIndex(lunar[0], lunar[1])];
  }

  static int getRokuyoColorIndex(String rokuyo) => rokuyoNames.indexOf(rokuyo);

  static List<int> _toLunar(DateTime date) => _julianToLunar(_toJulianDay(date));

  static double _toJulianDay(DateTime date) {
    int y = date.year, m = date.month, d = date.day;
    if (m < 3) { y -= 1; m += 12; }
    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + d + b - 1524.5;
  }

  static List<int> _julianToLunar(double jd) {
    double k = ((jd - 2451550.1) / 29.530588853).floorToDouble();
    for (int i = 0; i < 14; i++) {
      double newMoon = _calcNewMoon(k + i);
      double nextNewMoon = _calcNewMoon(k + i + 1);
      if (newMoon <= jd && jd < nextNewMoon) {
        return [_getLunarMonth(k + i), (jd - newMoon).floor() + 1];
      }
    }
    return [1, 1];
  }

  static double _calcNewMoon(double k) {
    double T = k / 1236.85;
    double T2 = T * T, T3 = T2 * T, T4 = T3 * T;
    double jde = 2451550.09766 + 29.530588861 * k + 0.00015437 * T2
        - 0.000000150 * T3 + 0.00000000073 * T4;
    double M = _degToRad(2.5534 + 29.10535670 * k - 0.0000014 * T2 - 0.00000011 * T3);
    double Mprime = _degToRad(201.5643 + 385.81693528 * k + 0.0107582 * T2
        + 0.00001238 * T3 - 0.000000058 * T4);
    double F = _degToRad(160.7108 + 390.67050284 * k - 0.0016118 * T2
        - 0.00000227 * T3 + 0.000000011 * T4);
    jde += -0.40720 * _sin(Mprime) + 0.17241 * _sin(M)
        + 0.01608 * _sin(2 * Mprime) + 0.01039 * _sin(2 * F)
        + 0.00739 * _sin(Mprime - M) - 0.00514 * _sin(Mprime + M);
    return jde;
  }

  static int _getLunarMonth(double k) => ((k % 12) + 12).toInt() % 12 + 1;
  static double _degToRad(double deg) => deg * 3.14159265358979 / 180.0;
  static double _sin(double rad) {
    double x = rad % (2 * 3.14159265358979);
    double result = x, term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}
```

---

## 和暦・祝日サービス（lib/services/japanese_calendar_service.dart）

```dart
class JapaneseCalendarService {
  static const List<Map<String, dynamic>> eras = [
    {'name': '令和', 'start': 2019, 'startMonth': 5,  'startDay': 1},
    {'name': '平成', 'start': 1989, 'startMonth': 1,  'startDay': 8},
    {'name': '昭和', 'start': 1926, 'startMonth': 12, 'startDay': 25},
    {'name': '大正', 'start': 1912, 'startMonth': 7,  'startDay': 30},
    {'name': '明治', 'start': 1868, 'startMonth': 10, 'startDay': 23},
  ];

  // toJapaneseEra(2025, 4, 1) → "令和7年"
  // toJapaneseEra(1989, 1, 8) → "平成元年"
  static String toJapaneseEra(int year, [int month = 1, int day = 1]) {
    for (final era in eras) {
      final s = era['start'] as int, sm = era['startMonth'] as int, sd = era['startDay'] as int;
      if (year > s || (year == s && month > sm) || (year == s && month == sm && day >= sd)) {
        int eraYear = year - s + 1;
        return eraYear == 1 ? '${era['name']}元年' : '${era['name']}${eraYear}年';
      }
    }
    return '${year}年';
  }

  static String getEraName(int year, [int month = 1, int day = 1]) { ... }
  static int getEraYear(int year, [int month = 1, int day = 1]) { ... }

  // 年齢計算画面用・全元号早見表リスト
  static List<Map<String, dynamic>> getAllErasForYear(int targetYear) {
    return eras.map((era) => {
      'eraName': era['name'],
      'startYear': era['start'],
      'startMonth': era['startMonth'],
      'targetWareki': _calcEraYear(targetYear, era['start'] as int, era['name'] as String),
    }).toList();
  }
}

class JapaneseHolidayService {
  // 固定祝日：元日・建国記念の日・天皇誕生日・昭和の日・憲法記念日・
  //          みどりの日・こどもの日・山の日・文化の日・勤労感謝の日
  // 移動祝日：成人の日(1月第2月曜)・海の日(7月第3月曜)・
  //          敬老の日(9月第3月曜)・スポーツの日(10月第2月曜)
  // 春分の日・秋分の日（天文計算概算式）
  // 振替休日（日曜祝日の翌平日）
  static Map<String, String> getHolidays(int year) { ... }
  static String? getHoliday(DateTime date) { ... }
}
```

---

## 法事計算サービス（lib/services/memorial_service.dart）

```dart
import 'package:temple_calendar/services/japanese_calendar_service.dart';

class MemorialService {
  static const List<int> nenki = [1, 3, 7, 13, 17, 23, 27, 33, 37, 50];

  static String getNenkiName(int n) {
    const names = {1:'一周忌',3:'三回忌',7:'七回忌',13:'十三回忌',17:'十七回忌',
      23:'二十三回忌',27:'二十七回忌',33:'三十三回忌',37:'三十七回忌',50:'五十回忌'};
    return names[n] ?? '${n}回忌';
  }

  // 一周忌 = 命日の翌年(+1年)
  // 三回忌 = 命日の2年後(+2年 = n-1年)
  static int getNenkiYear(DateTime deathDate, int n) {
    if (n == 1) return deathDate.year + 1;
    return deathDate.year + n - 1;
  }

  static List<Map<String, dynamic>> getNenkiList(DateTime deathDate) {
    return nenki.map((n) {
      final year = getNenkiYear(deathDate, n);
      DateTime nenkiDate;
      try {
        nenkiDate = DateTime(year, deathDate.month, deathDate.day);
      } catch (e) {
        // うるう日対応（2月29日など）
        nenkiDate = DateTime(year, deathDate.month + 1, 1).subtract(const Duration(days: 1));
      }
      return {
        'n': n,
        'name': getNenkiName(n),
        'year': year,
        'wareki': JapaneseCalendarService.toJapaneseEra(year, deathDate.month, deathDate.day),
        'date': nenkiDate,
        'monthDay': '${deathDate.month}月${deathDate.day}日',
      };
    }).toList();
  }

  // 満年齢（誕生日を迎えると1歳加算）
  static int calcAge(DateTime birthDate, DateTime today) {
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age;
  }

  // 数え年（生まれた年を1歳とし、元旦に加算）
  static int calcKazoeAge(DateTime birthDate, DateTime today) =>
      today.year - birthDate.year + 1;

  // 四十九日：命日を1日目として49日目（+48日）
  static DateTime calc49Days(DateTime deathDate) =>
      deathDate.add(const Duration(days: 48));

  // 百か日：命日を1日目として100日目（+99日）
  static DateTime calc100Days(DateTime deathDate) =>
      deathDate.add(const Duration(days: 99));

  // 中陰（初七日〜七七日）：7日ごと7回
  static List<Map<String, dynamic>> getIntervalDays(DateTime deathDate) {
    const dayNames = ['初七日','二七日','三七日','四七日','五七日','六七日','四十九日'];
    return List.generate(7, (i) => {
      'name': dayNames[i],
      'days': (i + 1) * 7,
      'date': deathDate.add(Duration(days: (i + 1) * 7 - 1)),
    });
  }
}
```

---

## 和暦日付ピッカー（lib/widgets/wareki_date_picker.dart）

```dart
class WarekiDatePicker extends StatefulWidget {
  final DateTime initialDate, firstDate, lastDate;
  final String title;    // カスタマイズ可能
  final IconData icon;   // カスタマイズ可能

  // 使い方:
  // 生年月日: WarekiDatePicker.show(context, title: '生年月日を選択', icon: Icons.cake, ...)
  // 没年月日: WarekiDatePicker.show(context, title: '没年月日を選択', icon: Icons.event, ...)

  static Future<DateTime?> show(BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String title = '生年月日を選択',
    IconData icon = Icons.cake,
  }) => showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (_) => WarekiDatePicker(
      initialDate: initialDate, firstDate: firstDate, lastDate: lastDate,
      title: title, icon: icon,
    ),
  );
}
```

**ピッカーUI仕様:**
- `ListWheelScrollView.useDelegate` で年・月・日を3列表示
- 年列（flex: 5）: 「昭和12年・1937年」形式（和暦＋西暦併記）
- 月列（flex: 2）: 「1月」〜「12月」
- 日列（flex: 2）: 「1日」〜「末日（月次可変）」
- `itemExtent: 40`, `perspective: 0.003`, `diameterRatio: 2.0`
- 選択中ハイライト帯（ゴールド半透明＋ボーダー）
- 確認プレビュー：「1937年12月15日 / 昭和12年」形式
- 選択年範囲: firstDate〜lastDate（年齢計算は明治元年〜今日、法事は明治元年〜今日）

---

## カレンダーグリッド（lib/widgets/calendar_grid.dart）

```dart
class CalendarGrid extends StatelessWidget {
  final int year, month;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  // GridView（7列、childAspectRatio: 0.75）
  // 曜日ヘッダー: 日=赤, 土=青, 他=白
  // 日付セル:
  //   - isToday: ゴールド円背景（BoxShape.circle）
  //   - isSelected: ゴールド枠（Border.all）
  //   - 日曜/祝日: 赤色テキスト
  //   - 土曜: 青色テキスト
  //   - 六曜: 日付下に8px小文字（個別ON/OFFフィルター対応）
  //   - 祝日: 赤い4px小ドット
}
```

---

## 画面構成（BottomNavigationBar 4タブ）

### タブ1: カレンダー画面（lib/screens/calendar_screen.dart）

```
機能:
- 月間カレンダー表示（2000年〜2050年 = 612ページ）
- PageView でスワイプ月切替（水平スワイプ）
- ヘッダー: 🏯 寺院カレンダー + 六曜 ON/OFF スイッチ
- 年月タップで年月ピッカーダイアログ（DropdownButton）
  - 年: 「2025年（令和7年）」形式で和暦併記
  - 月: 1〜12月
- ヘッダー中央: 西暦年月（大）+ 和暦（小・ゴールド）同時表示
- 日付タップでBottomSheet詳細（六曜・祝日・和暦表示）
- 月ごとの祝日一覧カード
- 六曜カラー凡例カード（表示中の六曜のみ）
```

### タブ2: 年齢計算画面（lib/screens/age_screen.dart）

```
機能:
- WarekiDatePicker で生年月日入力（title='生年月日を選択', icon=Icons.cake）
- 範囲: 明治元年（1868/10/23）〜今日
- 満年齢・数え年を並列カード表示
- 基準日（本日）・生年月日の西暦と和暦を詳細表示
- 和暦・西暦対応表（生まれ年の和暦確認）
- 元号早見表: 明治・大正・昭和・平成・令和の元年と西暦対応
  - 該当元号をゴールドでハイライト

満年齢計算:
  int age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) age--;

数え年計算:
  int kazoeAge = today.year - birthDate.year + 1;
```

### タブ3: 法事計算画面（lib/screens/memorial_screen.dart）

```
CRITICAL: TabBarView を使わず手動タブ実装（スクロール競合防止）

状態変数: int _selectedTab = 0;  // 0=年忌法要, 1=49日・100ヶ日

構成:
  Column(
    children: [
      _buildHeader(),   // 命日入力
      _buildTabBar(),   // GestureDetector で手動タブ切替
      Expanded(
        child: _selectedTab == 0
            ? ListView.builder(physics: ClampingScrollPhysics())
            : ListView(physics: ClampingScrollPhysics()),
      ),
    ],
  )

命日入力:
  WarekiDatePicker.show(context,
    title: '没年月日を選択',
    icon: Icons.event,
    firstDate: DateTime(1868, 10, 23),
    lastDate: DateTime.now(),
  )

タブA（年忌法要）:
  対象: 1・3・7・13・17・23・27・33・37・50 回忌
  - 今年の回忌: ゴールドハイライト + 「今年」バッジ
  - 過去の回忌: グレーアウト + 「済」バッジ + check_circleアイコン
  - 各行: 回忌バッジ（円）+ 名称 + 西暦年月日 + 曜日 + 和暦
  - 先頭に命日サマリーカード

タブB（49日・100ヶ日）:
  - 命日サマリーカード
  - 主要法要日カード（四十九日・百か日）
    - 残り日数カウントダウン（「あとN日」「本日」表示）
    - 過去の場合は check_circle アイコン
  - 中陰カード（初七日〜七七日、7日ごと）
    - 七七日（四十九日）は特別にゴールドハイライト
    - 残り日数表示
  - 計算説明カード
```

### タブ4: 設定画面（lib/screens/settings_screen.dart）

```
機能:
- 六曜をまとめてON/OFF（グローバルスイッチ）
- 六曜6種類を個別ON/OFF
  - 大安（金）・友引（緑）・先勝（青）・先負（紫）・仏滅（赤）・赤口（茶）
  - 各六曜の意味説明テキスト付き
  - グローバルOFF時は個別スイッチを半透明で無効化
  - 「すべてON」「すべてOFF」ボタン
- アプリ情報カード
  - アプリ名・バージョン・対応年範囲・和暦対応元号
- 年忌法要の計算方法説明カード
```

---

## Android設定

### strings.xml（新規作成）
```xml
<!-- android/app/src/main/res/values/strings.xml -->
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Temple Calendar coyomi</string>
</resources>
```

### AndroidManifest.xml
```xml
android:label="@string/app_name"
```

### android/app/build.gradle.kts
```kotlin
namespace = "com.templecalendar.coyomi.calendar"
applicationId = "com.templecalendar.coyomi.calendar"

// 署名設定
signingConfigs {
    create("release") {
        val keystoreProperties = Properties()
        val keystorePropertiesFile = rootProject.file("key.properties")
        if (keystorePropertiesFile.exists()) {
            keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
        }
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
    }
}
```

### MainActivity.kt
```kotlin
// パス: android/app/src/main/kotlin/com/templecalendar/coyomi/calendar/MainActivity.kt
package com.templecalendar.coyomi.calendar

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

---

## プライバシーポリシー

ファイル: `web/privacy_policy.html`（`build/web` にもコピー）

```html
<!-- ネイビー×ゴールドのデザインと統一 -->
<!-- 記載内容: -->
<!-- - 個人情報収集なし（全ての計算・表示はデバイス内で完結） -->
<!-- - 外部通信なし（インターネット接続不要） -->
<!-- - 権限不要 -->
<!-- - 設定情報はデバイスのローカルストレージに保存 -->
<!-- - お問い合わせ先 -->
```

GitHub: https://github.com/biroad-g/Temple-Calendar
公開URL（GitHub Pages / Vercel）: `https://[your-domain]/privacy_policy.html`

---

## 重要な実装メモ

### 1. スクロール競合の解決（法事計算画面）

**問題**: `TabBarView` 内では、横スワイプのジェスチャー認識が縦スクロールを阻害する。

**解決**: `TabBarView` を一切使わず、手動でタブ状態を管理する。

```dart
// ❌ 使用しない
DefaultTabController(...)
TabBar(...)
TabBarView(...)  // ← これがスクロール競合の原因

// ✅ 正しい実装
int _selectedTab = 0;

// タブバー
GestureDetector(
  onTap: () => setState(() => _selectedTab = index),
  ...
)

// コンテンツ（Expanded + ListView で縦スクロール確保）
Expanded(
  child: ListView(physics: const ClampingScrollPhysics(), ...),
)
```

### 2. 年忌計算のルール

```dart
// 一周忌 = 命日の翌年（+1年）
// 三回忌 = 命日の2年後（+2年 = n-1年）
// 七回忌 = 命日の6年後（+6年 = n-1年）
static int getNenkiYear(DateTime deathDate, int n) {
  if (n == 1) return deathDate.year + 1;
  return deathDate.year + n - 1;
}
```

### 3. 四十九日・百か日の計算

```dart
// 命日を「1日目」として数える
static DateTime calc49Days(DateTime deathDate) =>
    deathDate.add(const Duration(days: 48));  // +48日 = 49日目

static DateTime calc100Days(DateTime deathDate) =>
    deathDate.add(const Duration(days: 99));  // +99日 = 100日目
```

### 4. 和暦変換の注意点

```dart
// 元年判定：eraYear == 1 のとき「令和元年」と表示（数字は使わない）
if (eraYear == 1) return '${era['name']}元年';
return '${era['name']}${eraYear}年';
```

### 5. 六曜の個別ON/OFF

```dart
// グローバルスイッチ OFF → isRokuyoVisible() は常に false
bool isRokuyoVisible(String rokuyo) {
  if (!_showRokuyo) return false;  // グローバルOFF
  return _rokuyoVisibility[rokuyo] ?? true;  // 個別設定
}
```

### 6. `withOpacity` は非推奨 → `withValues` を使用

```dart
// ❌ 非推奨
AppTheme.gold.withOpacity(0.5)

// ✅ 正しい
AppTheme.gold.withValues(alpha: 0.5)
```

### 7. `print()` は非推奨

```dart
// ❌ flutter analyze で警告
print('debug');

// ✅ 正しい
import 'package:flutter/foundation.dart';
if (kDebugMode) debugPrint('debug');
```

---

## ビルド・署名手順

```bash
# Web ビルド
flutter build web --release

# AAB ビルド（署名済み）
flutter build appbundle --release

# 署名ファイル
android/release-key.jks        # キーストア
android/key.properties         # storePassword, keyPassword, keyAlias, storeFile
```

**証明書 SHA-256**:
`0B:1B:FF:4C:79:00:4B:4D:AE:B4:6D:5D:C7:84:17:3B:9B:47:BB:09:5E:78:3A:09:FC:06:82:FA:A9:56:3B:86`

---

## バージョン履歴

| バージョン | 変更内容 |
|-----------|---------|
| 1.0.0+1 | 初回リリース |
| 1.0.1+2 | アプリ名・パッケージ名変更（Temple Calendar coyomi / com.templecalendar.coyomi.calendar）、プライバシーポリシー追加、法事計算スクロール修正（TabBarView→手動タブ）、命日ピッカータイトルを「没年月日を選択」に変更 |

---

## 依存関係の最小バージョン

```
Flutter: 3.x
Dart: 3.x
shared_preferences: 2.5.3（SharedPreferences で六曜ON/OFFを永続化）
provider: 6.1.5+1（AppState の状態管理）
intl: 0.20.2（日本語ロケール対応）
flutter_localizations: flutter SDK バンドル
```

---

*このプロンプトを使用することで、Temple Calendar coyomi（v1.0.1+2）と同等のアプリを完全に再現できます。*
*最終更新: 2025年（令和7年）*
