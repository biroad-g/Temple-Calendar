import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/rokuyo_service.dart';
import '../services/japanese_calendar_service.dart';
import '../theme/app_theme.dart';

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final today = DateTime.now();
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0=日, 1=月, ...
    final holidays = JapaneseHolidayService.getHolidays(year);

    return Column(
      children: [
        // 曜日ヘッダー
        _buildWeekdayHeader(),
        const SizedBox(height: 4),
        // カレンダーグリッド
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.68,
          ),
          itemCount: startWeekday + lastDay.day,
          itemBuilder: (context, index) {
            if (index < startWeekday) {
              return const SizedBox.shrink();
            }
            final day = index - startWeekday + 1;
            final date = DateTime(year, month, day);
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isSelected = selectedDate != null &&
                date.year == selectedDate!.year &&
                date.month == selectedDate!.month &&
                date.day == selectedDate!.day;
            final isSunday = date.weekday == DateTime.sunday;
            final isSaturday = date.weekday == DateTime.saturday;
            final dateKey = '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            final holidayName = holidays[dateKey];
            final isHoliday = holidayName != null;

            String? rokuyo;
            if (appState.showRokuyo) {
              final r = RokuyoService.getRokuyo(date);
              // 個別ON/OFFフィルター
              if (appState.isRokuyoVisible(r)) {
                rokuyo = r;
              }
            }

            return GestureDetector(
              onTap: () => onDateSelected(date),
              child: _buildDayCell(
                day: day,
                isToday: isToday,
                isSelected: isSelected,
                isSunday: isSunday || isHoliday,
                isSaturday: isSaturday,
                rokuyo: rokuyo,
                holidayName: holidayName,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const days = ['日', '月', '火', '水', '木', '金', '土'];
    const colors = [
      AppTheme.red,
      AppTheme.white,
      AppTheme.white,
      AppTheme.white,
      AppTheme.white,
      AppTheme.white,
      AppTheme.blue,
    ];
    return Row(
      children: List.generate(7, (i) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: i == 0
                  ? AppTheme.red.withValues(alpha: 0.15)
                  : i == 6
                      ? AppTheme.blue.withValues(alpha: 0.15)
                      : AppTheme.navyLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              days[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors[i],
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell({
    required int day,
    required bool isToday,
    required bool isSelected,
    required bool isSunday,
    required bool isSaturday,
    String? rokuyo,
    String? holidayName,
  }) {
    Color dayColor = AppTheme.white;
    if (isSunday) dayColor = AppTheme.red;
    if (isSaturday) dayColor = AppTheme.blue;

    Color? rokuyoColor;
    if (rokuyo != null) {
      switch (rokuyo) {
        case '大安':
          rokuyoColor = AppTheme.taian;
          break;
        case '友引':
          rokuyoColor = AppTheme.tomobiki;
          break;
        case '先勝':
          rokuyoColor = AppTheme.sensho;
          break;
        case '先負':
          rokuyoColor = AppTheme.senbu;
          break;
        case '仏滅':
          rokuyoColor = AppTheme.butsumetsu;
          break;
        case '赤口':
          rokuyoColor = AppTheme.shakko;
          break;
        default:
          rokuyoColor = AppTheme.textMuted;
      }
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.gold.withValues(alpha: 0.3)
            : isToday
                ? AppTheme.gold.withValues(alpha: 0.15)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppTheme.gold, width: 1.5)
            : isSelected
                ? Border.all(color: AppTheme.gold, width: 1)
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 日付
          Container(
            width: 32,
            height: 32,
            decoration: isToday
                ? const BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                  )
                : null,
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isToday ? AppTheme.navyDark : dayColor,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          // 六曜
          if (rokuyo != null) ...[
            const SizedBox(height: 2),
            Text(
              rokuyo,
              style: TextStyle(
                color: rokuyoColor,
                fontSize: 11,
                fontWeight: rokuyo == '大安' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
          // 祝日
          if (holidayName != null) ...[
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppTheme.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
