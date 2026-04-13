import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/japanese_calendar_service.dart';
import '../services/rokuyo_service.dart';
import '../widgets/calendar_grid.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int _currentYear;
  late int _currentMonth;
  DateTime? _selectedDate;
  late PageController _pageController;
  final int _startYear = 2000;
  final int _endYear = 2050;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _selectedDate = now;
    final initialPage = (_currentYear - _startYear) * 12 + (_currentMonth - 1);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _pageToYear(int page) => _startYear + page ~/ 12;
  int _pageToMonth(int page) => page % 12 + 1;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final totalPages = (_endYear - _startYear + 1) * 12;

    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(appState),
            // カレンダー本体
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (page) {
                  setState(() {
                    _currentYear = _pageToYear(page);
                    _currentMonth = _pageToMonth(page);
                  });
                },
                itemBuilder: (context, page) {
                  final y = _pageToYear(page);
                  final m = _pageToMonth(page);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        CalendarGrid(
                          year: y,
                          month: m,
                          selectedDate: _selectedDate,
                          onDateSelected: (date) {
                            setState(() => _selectedDate = date);
                            _showDateDetail(date);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildRokuyoLegend(),
                        const SizedBox(height: 8),
                        _buildMonthHolidays(y, m),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.navyMedium,
        border: Border(
          bottom: BorderSide(color: AppTheme.gold, width: 1),
        ),
      ),
      child: Column(
        children: [
          // タイトルと六曜トグル
          Row(
            children: [
              const Text(
                '🏯',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                '寺院カレンダー',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 六曜トグル
              Row(
                children: [
                  Text(
                    '六曜',
                    style: TextStyle(
                      color: appState.showRokuyo ? AppTheme.gold : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: appState.showRokuyo,
                    onChanged: (_) => appState.toggleRokuyo(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 年月ナビゲーション
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppTheme.gold),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              GestureDetector(
                onTap: _showYearMonthPicker,
                child: Column(
                  children: [
                    Text(
                      '$_currentYear年$_currentMonth月',
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${JapaneseCalendarService.toJapaneseEra(_currentYear, _currentMonth)}  ／  $_currentYear年$_currentMonth月',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppTheme.gold),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRokuyoLegend() {
    final appState = context.watch<AppState>();
    if (!appState.showRokuyo) return const SizedBox.shrink();

    final allItems = [
      ('大安', AppTheme.taian),
      ('友引', AppTheme.tomobiki),
      ('先勝', AppTheme.sensho),
      ('先負', AppTheme.senbu),
      ('仏滅', AppTheme.butsumetsu),
      ('赤口', AppTheme.shakko),
    ];
    // 表示中の六曜のみ凡例に載せる
    final visibleItems = allItems
        .where((item) => appState.isRokuyoVisible(item.$1))
        .toList();

    if (visibleItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '六曜カラー凡例',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: visibleItems.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    item.$1,
                    style: TextStyle(
                      color: item.$2,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHolidays(int year, int month) {
    final holidays = JapaneseHolidayService.getHolidays(year);
    final monthHolidays = holidays.entries
        .where((e) {
          final parts = e.key.split('-');
          return int.parse(parts[1]) == month;
        })
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (monthHolidays.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: AppTheme.gold, size: 14),
              SizedBox(width: 4),
              Text(
                '祝日',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...monthHolidays.map((e) {
            final parts = e.key.split('-');
            final day = int.parse(parts[2]);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '$day日',
                        style: const TextStyle(
                          color: AppTheme.red,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.value,
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showYearMonthPicker() {
    showDialog(
      context: context,
      builder: (context) {
        int selectedYear = _currentYear;
        int selectedMonth = _currentMonth;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.navyMedium,
              title: const Text(
                '年月を選択',
                style: TextStyle(color: AppTheme.gold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 年選択
                  Row(
                    children: [
                      const Text('年:', style: TextStyle(color: AppTheme.white)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<int>(
                          value: selectedYear,
                          dropdownColor: AppTheme.navyMedium,
                          style: const TextStyle(color: AppTheme.white),
                          isExpanded: true,
                          items: List.generate(
                            _endYear - _startYear + 1,
                            (i) {
                              final y = _startYear + i;
                              final wareki = JapaneseCalendarService.toJapaneseEra(y);
                              return DropdownMenuItem(
                                value: y,
                                child: Text('$y年（$wareki）'),
                              );
                            },
                          ),
                          onChanged: (v) {
                            if (v != null) setState(() => selectedYear = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 月選択
                  Row(
                    children: [
                      const Text('月:', style: TextStyle(color: AppTheme.white)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<int>(
                          value: selectedMonth,
                          dropdownColor: AppTheme.navyMedium,
                          style: const TextStyle(color: AppTheme.white),
                          isExpanded: true,
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('${i + 1}月'),
                            ),
                          ),
                          onChanged: (v) {
                            if (v != null) setState(() => selectedMonth = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final page = (selectedYear - _startYear) * 12 +
                        (selectedMonth - 1);
                    _pageController.jumpToPage(page);
                  },
                  child: const Text('移動'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDateDetail(DateTime date) {
    final rokuyo = RokuyoService.getRokuyo(date);
    final holiday = JapaneseHolidayService.getHoliday(date);
    final wareki = JapaneseCalendarService.toJapaneseEra(
        date.year, date.month, date.day);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.navyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${date.year}年${date.month}月${date.day}日（${_weekdayName(date.weekday)}）',
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                wareki,
                style: const TextStyle(color: AppTheme.gold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (holiday != null)
                _detailRow(Icons.celebration, '祝日', holiday, AppTheme.red),
              _detailRow(
                Icons.auto_awesome,
                '六曜',
                rokuyo,
                _getRokuyoColor(rokuyo),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label：',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRokuyoColor(String rokuyo) {
    switch (rokuyo) {
      case '大安':
        return AppTheme.taian;
      case '友引':
        return AppTheme.tomobiki;
      case '先勝':
        return AppTheme.sensho;
      case '先負':
        return AppTheme.senbu;
      case '仏滅':
        return AppTheme.butsumetsu;
      case '赤口':
        return AppTheme.shakko;
      default:
        return AppTheme.textMuted;
    }
  }

  String _weekdayName(int weekday) {
    const names = ['月', '火', '水', '木', '金', '土', '日'];
    return names[weekday - 1];
  }
}
