import 'package:flutter/material.dart';
import '../services/japanese_calendar_service.dart';
import '../theme/app_theme.dart';

/// 和暦・西暦併記の日付ピッカーダイアログ
class WarekiDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final IconData icon;

  const WarekiDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title = '生年月日を選択',
    this.icon = Icons.cake,
  });

  /// ダイアログを表示して選択日を返す
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String title = '生年月日を選択',
    IconData icon = Icons.cake,
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (_) => WarekiDatePicker(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        title: title,
        icon: icon,
      ),
    );
  }

  @override
  State<WarekiDatePicker> createState() => _WarekiDatePickerState();
}

class _WarekiDatePickerState extends State<WarekiDatePicker> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  // 選択可能な年リスト
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;

    _years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (i) => widget.firstDate.year + i,
    );

    final yearIdx = _years.indexOf(_selectedYear);
    _yearController = FixedExtentScrollController(
        initialItem: yearIdx >= 0 ? yearIdx : 0);
    _monthController =
        FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _dayController =
        FixedExtentScrollController(initialItem: _selectedDay - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  /// 選択中の年月における最終日
  int get _daysInMonth =>
      DateTime(_selectedYear, _selectedMonth + 1, 0).day;

  /// 日が月の最終日を超えていたら修正
  void _clampDay() {
    if (_selectedDay > _daysInMonth) {
      _selectedDay = _daysInMonth;
      _dayController.jumpToItem(_selectedDay - 1);
    }
  }

  /// 年ラベル（「昭和12年・1937年」形式）
  String _yearLabel(int year) {
    final wareki = JapaneseCalendarService.toJapaneseEra(year);
    // "昭和12年" のような形式
    return '$wareki・${year}年';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.navyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            Row(
              children: [
                Icon(widget.icon, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppTheme.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 列ヘッダー
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Text(
                      '年',
                      style: TextStyle(
                        color: AppTheme.gold.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      '月',
                      style: TextStyle(
                        color: AppTheme.gold.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      '日',
                      style: TextStyle(
                        color: AppTheme.gold.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ──── スクロールピッカー本体 ────
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  // 選択中ハイライト帯
                  Center(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // ── 年列 ──
                      Expanded(
                        flex: 5,
                        child: ListWheelScrollView.useDelegate(
                          controller: _yearController,
                          itemExtent: 40,
                          perspective: 0.003,
                          diameterRatio: 2.0,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            setState(() {
                              _selectedYear = _years[i];
                              _clampDay();
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _years.length,
                            builder: (context, i) {
                              final year = _years[i];
                              final isSelected = year == _selectedYear;
                              return Center(
                                child: Text(
                                  _yearLabel(year),
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.gold
                                        : AppTheme.textLight
                                            .withValues(alpha: 0.5),
                                    fontSize: isSelected ? 13 : 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // ── 月列 ──
                      Expanded(
                        flex: 2,
                        child: ListWheelScrollView.useDelegate(
                          controller: _monthController,
                          itemExtent: 40,
                          perspective: 0.003,
                          diameterRatio: 2.0,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            setState(() {
                              _selectedMonth = i + 1;
                              _clampDay();
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 12,
                            builder: (context, i) {
                              final month = i + 1;
                              final isSelected = month == _selectedMonth;
                              return Center(
                                child: Text(
                                  '$month月',
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.white
                                        : AppTheme.textLight
                                            .withValues(alpha: 0.5),
                                    fontSize: isSelected ? 15 : 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // ── 日列 ──
                      Expanded(
                        flex: 2,
                        child: ListWheelScrollView.useDelegate(
                          controller: _dayController,
                          itemExtent: 40,
                          perspective: 0.003,
                          diameterRatio: 2.0,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (i) {
                            setState(() {
                              _selectedDay = i + 1;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _daysInMonth,
                            builder: (context, i) {
                              final day = i + 1;
                              final isSelected = day == _selectedDay;
                              return Center(
                                child: Text(
                                  '$day日',
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.white
                                        : AppTheme.textLight
                                            .withValues(alpha: 0.5),
                                    fontSize: isSelected ? 15 : 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 選択中の日付プレビュー
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.navyLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '$_selectedYear年$_selectedMonth月${_selectedDay}日',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    JapaneseCalendarService.toJapaneseEra(
                        _selectedYear, _selectedMonth, _selectedDay),
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ボタン行
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.navyLight),
                      foregroundColor: AppTheme.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final date = DateTime(
                          _selectedYear, _selectedMonth, _selectedDay);
                      Navigator.pop(context, date);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      '決定',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
