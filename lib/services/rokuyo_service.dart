/// 六曜計算サービス
/// 旧暦の月と日から六曜を計算する
class RokuyoService {
  static const List<String> rokuyoNames = [
    '先勝', '友引', '先負', '仏滅', '大安', '赤口'
  ];

  /// 六曜インデックスを取得（旧暦月+旧暦日 の余り）
  static int getRokuyoIndex(int lunarMonth, int lunarDay) {
    return (lunarMonth + lunarDay) % 6;
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

  /// 簡易旧暦変換（天文台アルゴリズムベース）
  static List<int> _toLunar(DateTime date) {
    // ユリウス日を計算
    final jd = _toJulianDay(date);
    return _julianToLunar(jd);
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

  static List<int> _julianToLunar(double jd) {
    // 朔（新月）の計算
    double k = ((jd - 2451550.1) / 29.530588853);
    k = k.floorToDouble();

    for (int i = 0; i < 14; i++) {
      double newMoon = _calcNewMoon(k + i);
      double nextNewMoon = _calcNewMoon(k + i + 1);
      if (newMoon <= jd && jd < nextNewMoon) {
        // 旧暦日 = JDから朔日を引いた日数+1
        int lunarDay = (jd - newMoon).floor() + 1;
        // 旧暦月の計算（簡易）
        int lunarMonth = _getLunarMonth(k + i);
        return [lunarMonth, lunarDay];
      }
    }
    return [1, 1];
  }

  static double _calcNewMoon(double k) {
    double T = k / 1236.85;
    double T2 = T * T;
    double T3 = T2 * T;
    double T4 = T3 * T;

    double jde = 2451550.09766 +
        29.530588861 * k +
        0.00015437 * T2 -
        0.000000150 * T3 +
        0.00000000073 * T4;

    double M = _degToRad(2.5534 + 29.10535670 * k - 0.0000014 * T2 - 0.00000011 * T3);
    double Mprime = _degToRad(201.5643 +
        385.81693528 * k +
        0.0107582 * T2 +
        0.00001238 * T3 -
        0.000000058 * T4);
    double F = _degToRad(160.7108 +
        390.67050284 * k -
        0.0016118 * T2 -
        0.00000227 * T3 +
        0.000000011 * T4);

    jde += -0.40720 * _sin(Mprime) +
        0.17241 * _sin(M) +
        0.01608 * _sin(2 * Mprime) +
        0.01039 * _sin(2 * F) +
        0.00739 * _sin(Mprime - M) -
        0.00514 * _sin(Mprime + M);

    return jde;
  }

  static int _getLunarMonth(double k) {
    // 簡易的に月番号を計算
    return ((k % 12) + 12).toInt() % 12 + 1;
  }

  static double _degToRad(double deg) => deg * 3.14159265358979 / 180.0;
  static double _sin(double rad) {
    // Dart's math.sin
    double x = rad % (2 * 3.14159265358979);
    // Taylor series approximation
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}
