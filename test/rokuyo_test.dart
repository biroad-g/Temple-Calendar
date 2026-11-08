import 'package:flutter_test/flutter_test.dart';
import 'package:temple_calendar/services/rokuyo_service.dart';

void main() {
  // 旧暦1日の六曜は 月番号により固定: 1月=先勝, 2月=友引, 3月=先負, 4月=仏滅, 5月=大安, 6月=赤口, 7月=先勝 ...
  final cases = <List<dynamic>>[
    [DateTime(2025, 1, 29), '先勝'], // 旧暦1/1
    [DateTime(2026, 2, 17), '先勝'], // 旧暦1/1
    [DateTime(2023, 1, 22), '先勝'], // 旧暦1/1
    [DateTime(2023, 5, 19), '友引'], // 旧暦3/30 (3+30-2=31%6=1 → 友引)
    [DateTime(2023, 5, 20), '仏滅'], // 旧暦4/1
    [DateTime(2023, 3, 22), '友引'], // 閏2/1
    [DateTime(2025, 7, 25), '赤口'], // 閏6/1
    [DateTime(2025, 8, 23), '先勝'], // 7/1
    [DateTime(2024, 2, 10), '先勝'], // 1/1
    [DateTime(2024, 1, 1), '赤口'],  // 旧暦11/20 (11+20-2=29%6=5 → 赤口)
  ];
  test('旧暦1日の六曜', () {
    for (final c in cases) {
      final d = c[0] as DateTime;
      // ignore: avoid_print
      print('${d.year}-${d.month}-${d.day} => ${RokuyoService.getRokuyo(d)}');
    }
    expect(RokuyoService.getRokuyo(DateTime(2025, 1, 29)), '先勝');
    expect(RokuyoService.getRokuyo(DateTime(2026, 2, 17)), '先勝');
    expect(RokuyoService.getRokuyo(DateTime(2023, 1, 22)), '先勝');
    expect(RokuyoService.getRokuyo(DateTime(2023, 5, 19)), '友引');
    expect(RokuyoService.getRokuyo(DateTime(2023, 5, 20)), '仏滅');
    expect(RokuyoService.getRokuyo(DateTime(2024, 1, 1)), '赤口');
    expect(RokuyoService.getRokuyo(DateTime(2023, 3, 22)), '友引');
    expect(RokuyoService.getRokuyo(DateTime(2025, 7, 25)), '赤口');
    expect(RokuyoService.getRokuyo(DateTime(2025, 8, 23)), '先勝');
    expect(RokuyoService.getRokuyo(DateTime(2024, 2, 10)), '先勝');
  });
  test('テーブル範囲で例外やフォールバックが出ない', () {
    var d = DateTime(1998, 1, 1);
    while (d.isBefore(DateTime(2050, 12, 1))) {
      final r = RokuyoService.getRokuyo(d);
      expect(RokuyoService.rokuyoNames.contains(r), true);
      d = d.add(const Duration(days: 1));
    }
  });
  test('連続する日は六曜が順に進む(月替わり以外)', () {
    var d = DateTime(2024, 1, 1);
    var jumps = 0;
    while (d.isBefore(DateTime(2026, 1, 1))) {
      final a = RokuyoService.rokuyoNames.indexOf(RokuyoService.getRokuyo(d));
      final b = RokuyoService.rokuyoNames
          .indexOf(RokuyoService.getRokuyo(d.add(const Duration(days: 1))));
      if ((a + 1) % 6 != b) jumps++;
      d = d.add(const Duration(days: 1));
    }
    // ignore: avoid_print
    print('月替わりでの並び替わり回数(2年間): $jumps');
    expect(jumps > 0 && jumps < 30, true);
  });
}
