import 'dart:math' as dart_math;

// 六曜計算サービス
// 修正履歴:
// - 旧暦月の計算を各年の旧暦元旦(k値)を基準に修正
// - 六曜計算式を (lunarMonth + lunarDay - 2) % 6 に変更
// - 2000〜2050年の旧暦元旦k値テーブルを追加

class RokuyoService {
  static const List<String> rokuyoNames = [
    '先勝', '友引', '先負', '仏滅', '大安', '赤口'
  ];

  /// 各年の旧暦元旦（旧暦1月1日）に対応する朔のk値テーブル
  /// k値 = (JD - 2451550.1) / 29.530588853 で求められる朔の番号
  /// 旧暦元旦の朔はグレゴリオ暦の1月21日〜2月20日の間に来る
  static const Map<int, int> _chineseNewYearK = {
    2000: 1,   // 2000/02/05
    2001: 13,  // 2001/01/24
    2002: 26,  // 2002/02/12
    2003: 38,  // 2003/02/01
    2004: 50,  // 2004/01/21
    2005: 63,  // 2005/02/08
    2006: 75,  // 2006/01/29
    2007: 88,  // 2007/02/17
    2008: 100, // 2008/02/07
    2009: 112, // 2009/01/26
    2010: 125, // 2010/02/14
    2011: 137, // 2011/02/03
    2012: 149, // 2012/01/23
    2013: 162, // 2013/02/10
    2014: 174, // 2014/01/30
    2015: 187, // 2015/02/18
    2016: 199, // 2016/02/08
    2017: 211, // 2017/01/28
    2018: 224, // 2018/02/15
    2019: 236, // 2019/02/04
    2020: 248, // 2020/01/24
    2021: 261, // 2021/02/11
    2022: 273, // 2022/02/01
    2023: 285, // 2023/01/21
    2024: 298, // 2024/02/09
    2025: 310, // 2025/01/29
    2026: 323, // 2026/02/17
    2027: 335, // 2027/02/06
    2028: 347, // 2028/01/26
    2029: 360, // 2029/02/13
    2030: 372, // 2030/02/02
    2031: 384, // 2031/01/23
    2032: 397, // 2032/02/11
    2033: 409, // 2033/01/30
    2034: 422, // 2034/02/18
    2035: 434, // 2035/02/08
    2036: 446, // 2036/01/28
    2037: 459, // 2037/02/15
    2038: 471, // 2038/02/04
    2039: 483, // 2039/01/24
    2040: 496, // 2040/02/12
    2041: 508, // 2041/02/01
    2042: 520, // 2042/01/21
    2043: 533, // 2043/02/09
    2044: 545, // 2044/01/30
    2045: 558, // 2045/02/16
    2046: 570, // 2046/02/05
    2047: 582, // 2047/01/26
    2048: 595, // 2048/02/14
    2049: 607, // 2049/02/02
    2050: 619, // 2050/01/23
  };

  /// 六曜インデックスを取得
  /// 正しい計算式: (旧暦月 + 旧暦日 - 2) % 6
  /// 旧暦1月1日=先勝(0), 2月1日=友引(1), ... となる
  static int getRokuyoIndex(int lunarMonth, int lunarDay) {
    return ((lunarMonth + lunarDay - 2) % 6 + 6) % 6;
  }

  /// グレゴリオ暦から六曜名を取得
  static String getRokuyo(DateTime date) {
    final lunar = _toLunar(date);
    final index = getRokuyoIndex(lunar[0], lunar[1]);
    return rokuyoNames[index];
  }

  /// 六曜の色インデックスを返す（表示用）
  static int getRokuyoColorIndex(String rokuyo) {
    return rokuyoNames.indexOf(rokuyo);
  }

  /// グレゴリオ暦から旧暦[月, 日]を取得
  static List<int> _toLunar(DateTime date) {
    final jd = _toJulianDay(date);
    return _julianToLunar(jd, date.year);
  }

  static double _toJulianDay(DateTime date) {
    int y = date.year;
    int m = date.month;
    int d = date.day;
    if (m < 3) {
      y -= 1;
      m += 12;
    }
    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  static List<int> _julianToLunar(double jd, int year) {
    // 朔（新月）の計算
    double k = ((jd - 2451550.1) / 29.530588853);
    k = k.floorToDouble();

    for (int i = 0; i < 14; i++) {
      double newMoon = _calcNewMoon(k + i);
      double nextNewMoon = _calcNewMoon(k + i + 1);
      if (newMoon <= jd && jd < nextNewMoon) {
        // 旧暦日 = JDから朔日を引いた日数+1
        int lunarDay = (jd - newMoon).floor() + 1;
        // 旧暦月の計算（旧暦元旦k値テーブルを使用）
        int lunarMonth = _getLunarMonthFromTable(k + i, year);
        return [lunarMonth, lunarDay];
      }
    }
    return [1, 1];
  }

  /// 旧暦元旦k値テーブルを基に旧暦月番号を計算
  /// k値から該当年の旧暦元旦kとの差分で月番号を決定
  static int _getLunarMonthFromTable(double kDouble, int year) {
    int k = kDouble.round();

    // 当年の旧暦元旦kを取得
    int? kNy = _chineseNewYearK[year];
    if (kNy != null) {
      int diff = k - kNy;
      if (diff >= 0 && diff < 13) {
        return diff + 1;
      }
    }

    // 前年の旧暦元旦からチェック（年末の日付が前年旧暦に属する場合）
    int? kNyPrev = _chineseNewYearK[year - 1];
    if (kNyPrev != null) {
      int diff = k - kNyPrev;
      if (diff >= 0 && diff < 14) {
        return diff + 1;
      }
    }

    // 翌年の旧暦元旦からチェック（年初の日付が翌年旧暦に属する場合）
    int? kNyNext = _chineseNewYearK[year + 1];
    if (kNyNext != null) {
      int diff = k - kNyNext;
      if (diff >= -1 && diff < 13) {
        return diff + 1;
      }
    }

    // フォールバック: 簡易計算
    return ((k % 12) + 12) % 12 + 1;
  }

  static double _calcNewMoon(double k) {
    double t = k / 1236.85;
    double t2 = t * t;
    double t3 = t2 * t;
    double t4 = t3 * t;

    double jde = 2451550.09766 +
        29.530588861 * k +
        0.00015437 * t2 -
        0.000000150 * t3 +
        0.00000000073 * t4;

    double mAnom = _degToRad(2.5534 + 29.10535670 * k - 0.0000014 * t2 - 0.00000011 * t3);
    double mprime = _degToRad(201.5643 +
        385.81693528 * k +
        0.0107582 * t2 +
        0.00001238 * t3 -
        0.000000058 * t4);
    double f = _degToRad(160.7108 +
        390.67050284 * k -
        0.0016118 * t2 -
        0.00000227 * t3 +
        0.000000011 * t4);

    jde += -0.40720 * _sin(mprime) +
        0.17241 * _sin(mAnom) +
        0.01608 * _sin(2 * mprime) +
        0.01039 * _sin(2 * f) +
        0.00739 * _sin(mprime - mAnom) -
        0.00514 * _sin(mprime + mAnom);

    return jde;
  }

  static double _degToRad(double deg) => deg * dart_math.pi / 180.0;

  static double _sin(double rad) => dart_math.sin(rad);
}
