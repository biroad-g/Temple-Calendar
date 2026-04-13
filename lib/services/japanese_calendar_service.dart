/// 和暦変換サービス
class JapaneseCalendarService {
  static const List<Map<String, dynamic>> eras = [
    {'name': '令和', 'start': 2019, 'startMonth': 5, 'startDay': 1},
    {'name': '平成', 'start': 1989, 'startMonth': 1, 'startDay': 8},
    {'name': '昭和', 'start': 1926, 'startMonth': 12, 'startDay': 25},
    {'name': '大正', 'start': 1912, 'startMonth': 7, 'startDay': 30},
    {'name': '明治', 'start': 1868, 'startMonth': 10, 'startDay': 23},
  ];

  /// 西暦から和暦文字列を返す
  static String toJapaneseEra(int year, [int month = 1, int day = 1]) {
    for (final era in eras) {
      final startYear = era['start'] as int;
      final startMonth = era['startMonth'] as int;
      final startDay = era['startDay'] as int;

      if (year > startYear ||
          (year == startYear && month > startMonth) ||
          (year == startYear && month == startMonth && day >= startDay)) {
        int eraYear = year - startYear + 1;
        if (eraYear == 1) {
          return '${era['name']}元年';
        }
        return '${era['name']}${eraYear}年';
      }
    }
    return '${year}年';
  }

  /// 和暦の元号名を返す
  static String getEraName(int year, [int month = 1, int day = 1]) {
    for (final era in eras) {
      final startYear = era['start'] as int;
      final startMonth = era['startMonth'] as int;
      final startDay = era['startDay'] as int;

      if (year > startYear ||
          (year == startYear && month > startMonth) ||
          (year == startYear && month == startMonth && day >= startDay)) {
        return era['name'] as String;
      }
    }
    return '';
  }

  /// 和暦の年数を返す
  static int getEraYear(int year, [int month = 1, int day = 1]) {
    for (final era in eras) {
      final startYear = era['start'] as int;
      final startMonth = era['startMonth'] as int;
      final startDay = era['startDay'] as int;

      if (year > startYear ||
          (year == startYear && month > startMonth) ||
          (year == startYear && month == startMonth && day >= startDay)) {
        return year - startYear + 1;
      }
    }
    return year;
  }

  /// 全元号の早見表リストを返す（年齢計算画面用）
  static List<Map<String, dynamic>> getAllErasForYear(int targetYear) {
    return eras.map((era) {
      final startYear = era['start'] as int;
      final startMonth = era['startMonth'] as int;
      final name = era['name'] as String;
      return {
        'eraName': name,
        'startYear': startYear,
        'startMonth': startMonth,
        'targetWareki': _calcEraYear(targetYear, startYear, name),
      };
    }).toList();
  }

  static String _calcEraYear(int targetYear, int eraStartYear, String eraName) {
    final diff = targetYear - eraStartYear + 1;
    if (diff <= 0) return '（${eraName}以前）';
    if (diff == 1) return '${eraName}元年';
    return '$eraName${diff}年';
  }

  /// 西暦から和暦の文字列（月日なし・年のみ）
  static String toJapaneseEraYear(int year) {
    return toJapaneseEra(year);
  }
}

/// 日本の祝日サービス
class JapaneseHolidayService {
  /// 指定年の祝日マップを返す（月日 -> 祝日名）
  static Map<String, String> getHolidays(int year) {
    final Map<String, String> holidays = {};

    // 固定祝日
    holidays['$year-01-01'] = '元日';
    holidays['$year-02-11'] = '建国記念の日';
    holidays['$year-02-23'] = '天皇誕生日';
    holidays['$year-04-29'] = '昭和の日';
    holidays['$year-05-03'] = '憲法記念日';
    holidays['$year-05-04'] = 'みどりの日';
    holidays['$year-05-05'] = 'こどもの日';
    holidays['$year-08-11'] = '山の日';
    holidays['$year-11-03'] = '文化の日';
    holidays['$year-11-23'] = '勤労感謝の日';

    // 移動祝日
    // 成人の日：1月第2月曜日
    holidays[_nthWeekday(year, 1, DateTime.monday, 2)] = '成人の日';
    // 海の日：7月第3月曜日
    holidays[_nthWeekday(year, 7, DateTime.monday, 3)] = '海の日';
    // 敬老の日：9月第3月曜日
    holidays[_nthWeekday(year, 9, DateTime.monday, 3)] = '敬老の日';
    // スポーツの日：10月第2月曜日
    holidays[_nthWeekday(year, 10, DateTime.monday, 2)] = 'スポーツの日';

    // 春分の日（概算）
    int shunbun = _calcShunbun(year);
    holidays['$year-03-${shunbun.toString().padLeft(2, '0')}'] = '春分の日';

    // 秋分の日（概算）
    int shubun = _calcShubun(year);
    holidays['$year-09-${shubun.toString().padLeft(2, '0')}'] = '秋分の日';

    // 振替休日の処理
    _addFurikae(holidays, year);

    return holidays;
  }

  static String _nthWeekday(int year, int month, int weekday, int n) {
    DateTime date = DateTime(year, month, 1);
    int count = 0;
    while (count < n) {
      if (date.weekday == weekday) count++;
      if (count < n) date = date.add(const Duration(days: 1));
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static int _calcShunbun(int year) {
    if (year <= 1979) return (20.8357 + 0.242194 * (year - 1980) - ((year - 1983) / 4).floor()).floor();
    if (year <= 2099) return (20.8431 + 0.242194 * (year - 1980) - ((year - 1980) / 4).floor()).floor();
    return 21;
  }

  static int _calcShubun(int year) {
    if (year <= 1979) return (23.2588 + 0.242194 * (year - 1980) - ((year - 1983) / 4).floor()).floor();
    if (year <= 2099) return (23.2488 + 0.242194 * (year - 1980) - ((year - 1980) / 4).floor()).floor();
    return 23;
  }

  static void _addFurikae(Map<String, String> holidays, int year) {
    final keys = List<String>.from(holidays.keys);
    for (final key in keys) {
      final parts = key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if (date.weekday == DateTime.sunday) {
        DateTime next = date.add(const Duration(days: 1));
        while (holidays.containsKey('${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}')) {
          next = next.add(const Duration(days: 1));
        }
        holidays['${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}'] = '振替休日';
      }
    }
  }

  static String? getHoliday(DateTime date) {
    final holidays = getHolidays(date.year);
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return holidays[key];
  }
}
