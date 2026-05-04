import 'dart:math' as dart_math;

// 六曜計算サービス
// 修正履歴:
// v4 - 2024-2025年以外でも正しい六曜を返すよう修正
//      根本原因: 閏月(うるうづき)がある年は月シーケンス番号が
//      正しい旧暦月番号とずれてしまう問題を修正。
//      解決策: 閏月テーブル(_leapMonthTable)を追加し、
//      各月の正しい旧暦月番号を計算した月シーケンスを使用。
// v3 - 2027/2028年の朔JST計算ずれ問題を修正
//      旧暦元旦をJD値テーブル（公式データ基準）で管理し、
//      各月の朔日JDシーケンスを元旦JDを起点に計算する方式に変更。
// v2 - 旧暦月の計算を各年の旧暦元旦(k値)を基準に修正
//      六曜計算式を (lunarMonth + lunarDay - 2) % 6 に変更

class RokuyoService {
  static const List<String> rokuyoNames = [
    '先勝', '友引', '先負', '仏滅', '大安', '赤口'
  ];

  /// 各年の旧暦元旦（旧暦1月1日）に対応するグレゴリオ暦日付のユリウス日テーブル
  /// 国立天文台の公式データに基づく (JST基準)
  /// 値 = date_to_jd(year, month, day) = グレゴリオ日 0時UTCのJD
  static const Map<int, double> _chineseNewYearJD = {
    1998: 2450841.5, // 1998/01/28
    1999: 2451225.5, // 1999/02/16
    2000: 2451579.5, // 2000/02/05
    2001: 2451933.5, // 2001/01/24
    2002: 2452317.5, // 2002/02/12
    2003: 2452671.5, // 2003/02/01
    2004: 2453026.5, // 2004/01/22
    2005: 2453410.5, // 2005/02/09
    2006: 2453764.5, // 2006/01/29
    2007: 2454149.5, // 2007/02/18
    2008: 2454503.5, // 2008/02/07
    2009: 2454857.5, // 2009/01/26
    2010: 2455241.5, // 2010/02/14
    2011: 2455595.5, // 2011/02/03
    2012: 2455949.5, // 2012/01/23
    2013: 2456333.5, // 2013/02/10
    2014: 2456688.5, // 2014/01/31
    2015: 2457072.5, // 2015/02/19
    2016: 2457426.5, // 2016/02/08
    2017: 2457781.5, // 2017/01/28
    2018: 2458165.5, // 2018/02/16
    2019: 2458519.5, // 2019/02/05
    2020: 2458873.5, // 2020/01/25
    2021: 2459257.5, // 2021/02/12
    2022: 2459611.5, // 2022/02/01
    2023: 2459966.5, // 2023/01/22
    2024: 2460350.5, // 2024/02/10
    2025: 2460704.5, // 2025/01/29
    2026: 2461088.5, // 2026/02/17
    2027: 2461442.5, // 2027/02/06
    2028: 2461796.5, // 2028/01/26
    2029: 2462180.5, // 2029/02/13
    2030: 2462535.5, // 2030/02/03
    2031: 2462889.5, // 2031/01/23
    2032: 2463273.5, // 2032/02/11
    2033: 2463628.5, // 2033/01/31
    2034: 2464012.5, // 2034/02/19
    2035: 2464366.5, // 2035/02/08
    2036: 2464720.5, // 2036/01/28
    2037: 2465104.5, // 2037/02/15
    2038: 2465458.5, // 2038/02/04
    2039: 2465812.5, // 2039/01/24
    2040: 2466196.5, // 2040/02/12
    2041: 2466551.5, // 2041/02/01
    2042: 2466906.5, // 2042/01/22
    2043: 2467290.5, // 2043/02/10
    2044: 2467644.5, // 2044/01/30
    2045: 2468028.5, // 2045/02/17
    2046: 2468382.5, // 2046/02/06
    2047: 2468736.5, // 2047/01/26
    2048: 2469120.5, // 2048/02/14
    2049: 2469474.5, // 2049/02/02
    2050: 2469829.5, // 2050/01/23
  };

  /// 旧暦閏月テーブル: 年 → 閏月番号 (0=閏月なし)
  /// 国立天文台の公式データに基づく
  /// 閏月は旧暦でその月番号の月が2回繰り返される
  /// 例: 2023年は閏二月 → 旧暦2023年に2月が2回ある
  static const Map<int, int> _leapMonthTable = {
    1998: 5,  // 閏五月
    2001: 4,  // 閏四月
    2004: 2,  // 閏二月
    2006: 7,  // 閏七月
    2009: 5,  // 閏五月
    2012: 4,  // 閏四月
    2014: 9,  // 閏九月
    2017: 6,  // 閏六月
    2020: 4,  // 閏四月
    2023: 2,  // 閏二月
    2025: 6,  // 閏六月
    2028: 5,  // 閏五月
    2031: 3,  // 閏三月
    2033: 11, // 閏十一月
    2036: 6,  // 閏六月
    2039: 5,  // 閏五月
    2042: 2,  // 閏二月
    2044: 7,  // 閏七月
    2047: 5,  // 閏五月
    2050: 3,  // 閏三月
  };

  /// 六曜インデックスを取得
  /// 計算式: (旧暦月 + 旧暦日 - 2) % 6
  /// 旧暦1月1日=先勝(0), 2月1日=友引(1), 3月1日=先負(2), ...
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

  /// グレゴリオ暦からユリウス日を計算
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

  /// ユリウス日から旧暦[月, 日]を計算
  /// アルゴリズム:
  /// 1. 対象年（または前年）の旧暦元旦JD（公式テーブル値）を起点にする
  /// 2. 元旦の朔kを特定し、そこから各月の朔JDシーケンスを構築
  ///    (閏月テーブルを参照し、正しい旧暦月番号を割り当て)
  /// 3. 対象JDが属する朔区間を特定して旧暦月・日を計算
  /// 注: 元旦の朔日はテーブル値を優先することで、朔が深夜0時直後の場合の
  ///     JST変換ずれ問題（2027/2028等）を回避する
  static List<int> _julianToLunar(double jd, int year) {
    // 当年・前年の順でシーケンスを検索
    for (int tryYear in [year, year - 1]) {
      final months = _buildMonthSequence(tryYear);
      if (months == null) continue;

      for (int i = 0; i < months.length - 1; i++) {
        if (months[i][0] <= jd && jd < months[i + 1][0]) {
          final lunarMonth = months[i][1].toInt();
          final lunarDay = (jd - months[i][0]).floor() + 1;
          return [lunarMonth, lunarDay];
        }
      }
    }
    return [1, 1];
  }

  /// 指定年の旧暦元旦を起点とする朔日JDシーケンスを構築
  /// 戻り値: [朔日JD, 旧暦月番号] のリスト（閏月を正しく考慮）
  /// null = テーブルなし
  static List<List<double>>? _buildMonthSequence(int year) {
    final jdCny = _chineseNewYearJD[year];
    if (jdCny == null) return null;

    // 元旦に最も近い朔kを探す
    double kApprox = (jdCny - 2451550.1) / 29.530588853;
    int bestK = kApprox.floor();
    double bestDiff = (_calcNewMoon(bestK.toDouble()) - jdCny).abs();
    for (int dk = -2; dk <= 2; dk++) {
      int k = kApprox.floor() + dk;
      double diff = (_calcNewMoon(k.toDouble()) - jdCny).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestK = k;
      }
    }

    // 閏月情報を取得
    final leapMonth = _leapMonthTable[year] ?? 0;

    // 朔日JDシーケンスを構築 (各要素: [朔日JD, 旧暦月番号])
    final List<List<double>> months = [];

    // 旧暦1月（元旦）: テーブル値を使用（計算値でなく公式値）
    months.add([jdCny, 1.0]);

    int currentLunarMonth = 1;
    bool leapInserted = false;

    // 旧暦2月以降: k値から計算したJST朔日JD
    for (int i = 1; i <= 14; i++) {
      int k = bestK + i;
      double jde = _calcNewMoon(k.toDouble());
      // JDE(TT) → JST日付のJD
      double jdJst = jde + 9.0 / 24.0;
      // JSTでの日付（午前0時）に対応するJDを計算
      double newMoonJd = (jdJst + 0.5).floorToDouble() - 0.5;

      // 旧暦月番号を決定
      int lunarMonth;
      if (!leapInserted && leapMonth > 0 && currentLunarMonth == leapMonth) {
        // 閏月: 前月と同じ月番号が2回続く
        lunarMonth = currentLunarMonth;
        leapInserted = true;
      } else {
        // 通常月
        if (i == 1) {
          currentLunarMonth = 2;
        } else {
          currentLunarMonth++;
        }
        if (currentLunarMonth > 12) {
          currentLunarMonth = 1; // 翌年の1月
        }
        lunarMonth = currentLunarMonth;
      }

      months.add([newMoonJd, lunarMonth.toDouble()]);
    }

    return months;
  }

  /// 朔のJulian Day Ephemeris (JDE) を計算
  /// Meeus "Astronomical Algorithms" 第47章の式に基づく
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

    double mAnom = _degToRad(
        2.5534 + 29.10535670 * k - 0.0000014 * t2 - 0.00000011 * t3);
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
