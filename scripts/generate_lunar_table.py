#!/usr/bin/env python3
"""
旧暦月初日テーブル生成スクリプト (astronomy-engine 使用)

  pip install astronomy-engine
  python3 scripts/generate_lunar_table.py            # 検証のみ
  python3 scripts/generate_lunar_table.py --apply    # rokuyo_service.dart のテーブルを書き換え

ルール (国立天文台 暦要項と同じ考え方):
  - 朔(新月)の瞬間を日本標準時(JST, UTC+9)に直し、その日付を月の1日とする
  - 太陽黄経が30度の倍数になる瞬間(中気)をJSTの日付に直す
  - 中気を含む月 → 月番号: 黄経0°(春分)=2月, 30°=3月, ... 270°(冬至)=11月, 300°=12月, 330°=1月
  - 中気を含まない月 → 閏月 (直前の月と同じ番号, 'L' を付ける)
"""
import datetime as dt
import re
import sys

import astronomy as A

START_YEAR = 1997   # 旧暦年(旧暦1月1日が属するグレゴリオ暦年)
END_YEAR = 2050
# 2033年問題: 2033-08-25以降は天保暦の規則だけでは閏月が決まらないため、この日より前までを採用
CUTOFF = dt.date(2100, 1, 1)  # カットオフなし(2033年問題は OVERRIDES で暫定対応)

# 2033年問題の暫定対応: 閏11月説 (2033-12-22 を閏11月とする最も広く使われる解釈)
# 該当期間は規則だけでは月番号が決まらないため、この期間だけ手動で月番号を割り当てる。
OVERRIDES = {
    dt.date(2033, 8, 25): (8, False),  dt.date(2033, 9, 23): (9, False),
    dt.date(2033, 10, 23): (10, False), dt.date(2033, 11, 22): (11, False),
    dt.date(2033, 12, 22): (11, True),  dt.date(2034, 1, 20): (12, False),
    dt.date(2034, 2, 19): (1, False),
}
JST = dt.timedelta(hours=9)
DART = 'lib/services/rokuyo_service.dart'


def jst_date(t):
    d = t.Utc() + JST
    return dt.date(d.year, d.month, d.day)


def new_moons(y0, y1):
    res, t = [], A.Time.Make(y0, 1, 1, 0, 0, 0)
    while True:
        q = A.SearchMoonPhase(0, t, 40)
        d = jst_date(q)
        if d.year > y1:
            break
        res.append((d, q.Utc() + JST))
        t = q.AddDays(20)
    return res


def chuuki(y0, y1):
    """[(JST日付, 月番号)]"""
    res = []
    for y in range(y0, y1 + 1):
        for k in range(12):
            lon = k * 30
            # 年初から探すと同じ黄経が年内に1回だけ見つかる
            t = A.SearchSunLongitude(lon, A.Time.Make(y, 1, 1, 0, 0, 0), 400)
            d = jst_date(t)
            if d.year != y:
                continue
            month_no = (k + 2 - 1) % 12 + 1  # 0°->2, 30°->3, ..., 330°->1
            res.append((d, month_no))
    return sorted(set(res))


def build():
    nms = new_moons(START_YEAR - 1, END_YEAR + 1)
    cks = chuuki(START_YEAR - 1, END_YEAR + 1)
    months = []  # (start_date, month_no, is_leap)
    prev_no = None
    for i in range(len(nms) - 1):
        s, e = nms[i][0], nms[i + 1][0]
        inside = [no for d, no in cks if s <= d < e]
        if inside:
            no, leap = inside[0], False
        else:
            no, leap = prev_no, True
        if s in OVERRIDES:
            no, leap = OVERRIDES[s]
        months.append((s, no, leap))
        prev_no = no
    return months, nms


def check_sequence(months):
    """月番号が1ずつ進み、閏月は直前と同番号であることを確認"""
    errs = []
    months = [m for m in months if m[0] < CUTOFF]
    for i in range(1, len(months)):
        _, pn, _ = months[i - 1]
        s, n, leap = months[i]
        exp = pn if leap else pn % 12 + 1
        if n != exp:
            errs.append((s, pn, n, leap))
    return errs


def to_dart(months):
    # 旧暦年: 旧暦1月(非閏)の開始日のグレゴリオ年
    years = {}
    cur = None
    for s, n, leap in months:
        if s >= CUTOFF:
            continue
        if n == 1 and not leap:
            cur = s.year
        if cur is None:
            continue
        years.setdefault(cur, []).append((n, leap, s))
    lines = []
    for y in sorted(years):
        if y < START_YEAR or y > END_YEAR:
            continue
        lines.append(f'    {y}: [')
        row = []
        for n, leap, s in years[y]:
            tag = ('L%d' % n) if leap else str(n)
            row.append("['%s', %d, %d, %d]" % (tag, s.year, s.month, s.day))
        # 3件ずつ改行
        for i in range(0, len(row), 3):
            lines.append('      ' + ', '.join(row[i:i + 3]) + ',')
        lines.append('    ],')
    return '\n'.join(lines)


# 国立天文台で公表されている既知の値 (旧暦月初日)
KNOWN = {
    (2020, 4, 23): ('4', False), (2020, 5, 23): ('4', True), (2020, 6, 21): ('5', False),
    (2023, 1, 22): ('1', False), (2023, 2, 20): ('2', False), (2023, 3, 22): ('2', True),
    (2023, 4, 20): ('3', False), (2023, 5, 20): ('4', False),
    (2024, 2, 10): ('1', False),
    (2025, 1, 29): ('1', False), (2025, 7, 25): ('6', True), (2025, 8, 23): ('7', False),
    (2026, 2, 17): ('1', False),
}


def main():
    months, nms = build()
    errs = check_sequence([m for m in months if START_YEAR - 1 <= m[0].year <= END_YEAR])
    print('月番号の連続性エラー:', len(errs))
    for e in errs[:10]:
        print('  ', e)

    d2m = {m[0]: m for m in months}
    bad = 0
    for (y, mo, d), (no, leap) in KNOWN.items():
        m = d2m.get(dt.date(y, mo, d))
        got = None if m is None else (str(m[1]), m[2])
        ok = got == (no, leap)
        bad += 0 if ok else 1
        print('  既知値', (y, mo, d), '期待', (no, leap), '計算', got, 'OK' if ok else 'NG')
    print('既知値の不一致:', bad)

    # 朔の瞬間がJST 0時に近い(判定が微妙になり得る)ものを列挙
    close = [(d, t) for d, t in nms if START_YEAR <= d.year <= END_YEAR
             and min(t.hour * 60 + t.minute, 1440 - (t.hour * 60 + t.minute)) < 5]
    print('JST0時から5分以内の朔 (要注意):', len(close))
    for d, t in close:
        print('  ', t.strftime('%Y-%m-%d %H:%M:%S'))

    body = to_dart(months)
    open('/tmp/lunar_table_body.txt', 'w', encoding='utf-8').write(body)
    print('生成した旧暦年数:', body.count('\n    ],'))

    if '--apply' in sys.argv:
        if errs or bad:
            print('検証エラーがあるため適用しません')
            sys.exit(1)
        src = open(DART, encoding='utf-8').read()
        pat = re.compile(
            r'(static const Map<int, List<List<dynamic>>> _lunarMonthTable = \{\n)(.*?)(\n  \};)',
            re.S)
        if not pat.search(src):
            print('テーブルが見つかりません')
            sys.exit(1)
        src = pat.sub(lambda m: m.group(1) + body + m.group(3), src, count=1)
        open(DART, 'w', encoding='utf-8').write(src)
        print('適用しました:', DART)


if __name__ == '__main__':
    main()
