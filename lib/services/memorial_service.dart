import 'package:temple_calendar/services/japanese_calendar_service.dart';

/// 法事・年忌計算サービス
class MemorialService {
  /// 年忌法要リスト（回忌番号）
  static const List<int> nenki = [1, 3, 7, 13, 17, 23, 27, 33, 37, 50];

  /// 年忌の名称
  static String getNenkiName(int n) {
    if (n == 1) return '一周忌';
    if (n == 3) return '三回忌';
    if (n == 7) return '七回忌';
    if (n == 13) return '十三回忌';
    if (n == 17) return '十七回忌';
    if (n == 23) return '二十三回忌';
    if (n == 27) return '二十七回忌';
    if (n == 33) return '三十三回忌';
    if (n == 37) return '三十七回忌';
    if (n == 50) return '五十回忌';
    return '${n}回忌';
  }

  /// 命日から年忌の年（西暦）を計算
  /// 一周忌は翌年、三回忌は2年後（命日の年から数えて3年目）
  static int getNenkiYear(DateTime deathDate, int n) {
    if (n == 1) return deathDate.year + 1;
    return deathDate.year + n - 1;
  }

  /// 年忌の情報リストを返す
  static List<Map<String, dynamic>> getNenkiList(DateTime deathDate) {
    return nenki.map((n) {
      final year = getNenkiYear(deathDate, n);
      final month = deathDate.month;
      final day = deathDate.day;
      // 年忌は命日と同じ月日
      DateTime nenkiDate;
      try {
        nenkiDate = DateTime(year, month, day);
      } catch (e) {
        // うるう日対応（2月29日など）
        nenkiDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
      }
      final wareki = JapaneseCalendarService.toJapaneseEra(year, month, day);
      return {
        'n': n,
        'name': getNenkiName(n),
        'year': year,
        'wareki': wareki,
        'date': nenkiDate,
        'monthDay': '${month}月${day}日',
      };
    }).toList();
  }

  /// 満年齢を計算
  static int calcAge(DateTime birthDate, DateTime today) {
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// 数え年を計算（生まれた年を1歳とし、元旦に年齢が上がる）
  static int calcKazoeAge(DateTime birthDate, DateTime today) {
    return today.year - birthDate.year + 1;
  }

  /// 49日を計算
  static DateTime calc49Days(DateTime deathDate) {
    return deathDate.add(const Duration(days: 48)); // 命日含め49日
  }

  /// 100ヶ日を計算
  static DateTime calc100Days(DateTime deathDate) {
    return deathDate.add(const Duration(days: 99)); // 命日含め100日
  }

  /// 中間日程リスト（7日ごと）
  static List<Map<String, dynamic>> getIntervalDays(DateTime deathDate) {
    final List<Map<String, dynamic>> result = [];
    final dayNames = [
      '初七日', '二七日', '三七日', '四七日', '五七日', '六七日', '四十九日'
    ];
    for (int i = 0; i < 7; i++) {
      final days = (i + 1) * 7 - 1; // 命日含め
      final date = deathDate.add(Duration(days: days));
      result.add({
        'name': dayNames[i],
        'days': (i + 1) * 7,
        'date': date,
      });
    }
    return result;
  }

  /// 日付フォーマット
  static String formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日（${_weekdayName(date.weekday)}）';
  }

  static String _weekdayName(int weekday) {
    const names = ['月', '火', '水', '木', '金', '土', '日'];
    return names[weekday - 1];
  }
}
