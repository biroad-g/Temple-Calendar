import 'package:flutter/material.dart';
import '../services/memorial_service.dart';
import '../services/japanese_calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/wareki_date_picker.dart';

class MemorialScreen extends StatefulWidget {
  const MemorialScreen({super.key});

  @override
  State<MemorialScreen> createState() => _MemorialScreenState();
}

class _MemorialScreenState extends State<MemorialScreen> {
  DateTime? _deathDate;
  // TabBarView を使わず自前でタブを管理（スクロール競合を避けるため）
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── ヘッダー（命日入力） ──
            _buildHeader(),
            // ── 手動タブバー ──
            _buildTabBar(),
            // ── コンテンツ（Expanded + スクロール） ──
            Expanded(
              child: _selectedTab == 0
                  ? _buildNenkiContent()
                  : _buildDaysContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ヘッダー（命日入力） ────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.navyMedium,
        border: Border(bottom: BorderSide(color: AppTheme.gold, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🪷', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text(
                '法事計算',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 命日入力ボタン
          InkWell(
            onTap: _selectDeathDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.navyLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _deathDate != null ? AppTheme.gold : AppTheme.navyLight,
                  width: _deathDate != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: AppTheme.gold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _deathDate != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '命日（ご逝去日）',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 10),
                              ),
                              Text(
                                '${_deathDate!.year}年${_deathDate!.month}月${_deathDate!.day}日'
                                '（${_wd(_deathDate!.weekday)}曜日）',
                                style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                JapaneseCalendarService.toJapaneseEra(
                                    _deathDate!.year,
                                    _deathDate!.month,
                                    _deathDate!.day),
                                style: const TextStyle(
                                    color: AppTheme.gold, fontSize: 11),
                              ),
                            ],
                          )
                        : const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('命日（ご逝去日）',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 10)),
                              Text('命日を選択してください',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 14)),
                              Text('西暦・和暦どちらでも入力できます',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 10)),
                            ],
                          ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.gold),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 手動タブバー ───────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppTheme.navyMedium,
      child: Row(
        children: [
          _tabItem(0, '年忌法要'),
          _tabItem(1, '49日・100ヶ日'),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.gold : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.gold : AppTheme.textMuted,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ─── 年忌法要コンテンツ ─────────────────────────────────────
  Widget _buildNenkiContent() {
    if (_deathDate == null) {
      return _emptyState('命日を選択すると\n年忌法要の一覧が表示されます');
    }

    final nenkiList = MemorialService.getNenkiList(_deathDate!);
    final today = DateTime.now();

    // ListView.builder を直接 Expanded 配下に置く
    return ListView.builder(
      // physics を明示して縦スクロールを確実に有効化
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: nenkiList.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _summaryCard();

        final item = nenkiList[index - 1];
        final year = item['year'] as int;
        final nenkiDate = item['date'] as DateTime;
        final isPast = nenkiDate.isBefore(
            DateTime(today.year, today.month, today.day));
        final isThisYear = year == today.year;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isThisYear
                ? AppTheme.gold.withValues(alpha: 0.15)
                : isPast
                    ? AppTheme.navyMedium.withValues(alpha: 0.5)
                    : AppTheme.navyMedium,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isThisYear ? AppTheme.gold : AppTheme.navyLight,
              width: isThisYear ? 1.5 : 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 回忌バッジ
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isThisYear
                        ? AppTheme.gold
                        : isPast
                            ? AppTheme.navyLight
                            : AppTheme.navyLight.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['n'] == 1 ? '一' : '${item['n']}',
                          style: TextStyle(
                            color: isThisYear
                                ? AppTheme.navyDark
                                : AppTheme.textLight,
                            fontWeight: FontWeight.bold,
                            fontSize: item['n'] == 1 ? 14 : 13,
                          ),
                        ),
                        if (item['n'] != 1)
                          Text(
                            '回忌',
                            style: TextStyle(
                              color: isThisYear
                                  ? AppTheme.navyDark
                                  : AppTheme.textMuted,
                              fontSize: 8,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // テキスト情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['name'] as String,
                            style: TextStyle(
                              color:
                                  isThisYear ? AppTheme.gold : AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isThisYear)
                            _badge('今年', AppTheme.gold),
                          if (isPast && !isThisYear)
                            _badge('済', AppTheme.textMuted),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${year}年 ${item['monthDay']}'
                        '（${_wd((item['date'] as DateTime).weekday)}曜日）',
                        style: TextStyle(
                          color:
                              isPast ? AppTheme.textMuted : AppTheme.textLight,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        item['wareki'] as String,
                        style: TextStyle(
                          color: isPast ? AppTheme.textMuted : AppTheme.gold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                isPast
                    ? const Icon(Icons.check_circle,
                        color: AppTheme.textMuted, size: 20)
                    : const Icon(Icons.chevron_right,
                        color: AppTheme.gold, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 49日・100ヶ日コンテンツ ────────────────────────────────
  Widget _buildDaysContent() {
    if (_deathDate == null) {
      return _emptyState('命日を選択すると\n49日・100ヶ日が表示されます');
    }

    final day49 = MemorialService.calc49Days(_deathDate!);
    final day100 = MemorialService.calc100Days(_deathDate!);
    final intervalDays = MemorialService.getIntervalDays(_deathDate!);
    final today = DateTime.now();

    // ListView.builder で全アイテムを縦に並べる
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        _summaryCard(),
        _mainDaysCard(day49, day100, today),
        const SizedBox(height: 16),
        _chuinCard(intervalDays, today),
        const SizedBox(height: 16),
        _explanationCard(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── 命日サマリーカード ─────────────────────────────────────
  Widget _summaryCard() {
    if (_deathDate == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_florist, color: AppTheme.gold, size: 14),
              SizedBox(width: 6),
              Text('命日',
                  style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              Text(
                '${_deathDate!.year}年${_deathDate!.month}月${_deathDate!.day}日'
                '（${_wd(_deathDate!.weekday)}曜日）',
                style: const TextStyle(color: AppTheme.white, fontSize: 14),
              ),
              Text(
                JapaneseCalendarService.toJapaneseEra(
                    _deathDate!.year, _deathDate!.month, _deathDate!.day),
                style:
                    const TextStyle(color: AppTheme.gold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '※ 一周忌は翌年、三回忌は2年後、以降は回忌数-1年後',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ─── 主要法要日カード（49日・100ヶ日） ──────────────────────
  Widget _mainDaysCard(DateTime day49, DateTime day100, DateTime today) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.navyLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.flag, color: AppTheme.gold, size: 16),
                SizedBox(width: 6),
                Text('主要法要日',
                    style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
          _mainDayRow(
              icon: '🕯️',
              label: '四十九日',
              subLabel: '命日を1日目として49日目',
              date: day49,
              today: today,
              isImportant: true),
          const Divider(color: AppTheme.navyLight, height: 1),
          _mainDayRow(
              icon: '🪷',
              label: '百か日',
              subLabel: '命日を1日目として100日目',
              date: day100,
              today: today,
              isImportant: false),
        ],
      ),
    );
  }

  Widget _mainDayRow({
    required String icon,
    required String label,
    required String subLabel,
    required DateTime date,
    required DateTime today,
    required bool isImportant,
  }) {
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isPast = date.isBefore(todayOnly);
    final daysLeft = date.difference(todayOnly).inDays;
    final wareki =
        JapaneseCalendarService.toJapaneseEra(date.year, date.month, date.day);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: isImportant ? AppTheme.gold : AppTheme.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(subLabel,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  '${date.year}年${date.month}月${date.day}日（${_wd(date.weekday)}曜日）',
                  style:
                      const TextStyle(color: AppTheme.white, fontSize: 14),
                ),
                Text(wareki,
                    style: const TextStyle(
                        color: AppTheme.gold, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isPast)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isImportant
                    ? AppTheme.gold.withValues(alpha: 0.2)
                    : AppTheme.navyLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isImportant
                        ? AppTheme.gold
                        : AppTheme.navyLight),
              ),
              child: Text(
                daysLeft == 0
                    ? '本日'
                    : daysLeft > 0
                        ? 'あと\n$daysLeft日'
                        : '${-daysLeft}日前',
                style: TextStyle(
                    color: isImportant
                        ? AppTheme.gold
                        : AppTheme.textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            )
          else
            const Icon(Icons.check_circle,
                color: AppTheme.textMuted, size: 22),
        ],
      ),
    );
  }

  // ─── 中陰カード ─────────────────────────────────────────────
  Widget _chuinCard(
      List<Map<String, dynamic>> intervalDays, DateTime today) {
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.navyLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.timeline, color: AppTheme.gold, size: 16),
                SizedBox(width: 6),
                Text('中陰（七七日まで）',
                    style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
          ...intervalDays.asMap().entries.map((entry) {
            final item = entry.value;
            final date = item['date'] as DateTime;
            final isPast = date.isBefore(todayOnly);
            final isLast = entry.key == intervalDays.length - 1;
            final daysLeft = date.difference(todayOnly).inDays;

            return Column(
              children: [
                if (entry.key > 0)
                  const Divider(color: AppTheme.navyLight, height: 1),
                Container(
                  color: isLast
                      ? AppTheme.gold.withValues(alpha: 0.08)
                      : Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // 日数バッジ
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isLast
                                ? AppTheme.gold.withValues(alpha: 0.3)
                                : AppTheme.navyLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${item['days']}',
                              style: TextStyle(
                                  color: isLast
                                      ? AppTheme.gold
                                      : AppTheme.textLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // テキスト
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] as String,
                                style: TextStyle(
                                    color: isLast
                                        ? AppTheme.gold
                                        : AppTheme.white,
                                    fontWeight: isLast
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14),
                              ),
                              Text(
                                '${date.year}年${date.month}月${date.day}日（${_wd(date.weekday)}曜日）',
                                style: TextStyle(
                                    color: isPast
                                        ? AppTheme.textMuted
                                        : AppTheme.textLight,
                                    fontSize: 12),
                              ),
                              Text(
                                JapaneseCalendarService.toJapaneseEra(
                                    date.year, date.month, date.day),
                                style: TextStyle(
                                    color: isPast
                                        ? AppTheme.textMuted
                                        : AppTheme.gold,
                                    fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        // 残り日数
                        if (!isPast)
                          Text(
                            daysLeft == 0
                                ? '本日'
                                : 'あと${daysLeft}日',
                            style: TextStyle(
                                color: isLast
                                    ? AppTheme.gold
                                    : AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: isLast
                                    ? FontWeight.bold
                                    : FontWeight.normal),
                          )
                        else
                          const Icon(Icons.check,
                              color: AppTheme.textMuted, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── 説明カード ─────────────────────────────────────────────
  Widget _explanationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.gold, size: 16),
              SizedBox(width: 6),
              Text('計算について',
                  style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• 四十九日：命日を1日目として数え49日目\n'
            '• 百か日：命日を1日目として数え100日目\n'
            '• 中陰：命日から7日ごとの法要（初七日〜七七日）\n'
            '• 各日が土日の場合は前後に調整する場合があります\n'
            '• 宗派によって数え方が異なる場合があります',
            style: TextStyle(
                color: AppTheme.textMuted, fontSize: 11, height: 1.7),
          ),
        ],
      ),
    );
  }

  // ─── 空状態 ─────────────────────────────────────────────────
  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪷', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── バッジ ─────────────────────────────────────────────────
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // ─── 曜日名 ─────────────────────────────────────────────────
  String _wd(int weekday) {
    const names = ['月', '火', '水', '木', '金', '土', '日'];
    return names[weekday - 1];
  }

  // ─── 命日ピッカー ────────────────────────────────────────────
  Future<void> _selectDeathDate() async {
    final picked = await WarekiDatePicker.show(
      context,
      initialDate: _deathDate ?? DateTime.now(),
      firstDate: DateTime(1868, 10, 23),
      lastDate: DateTime.now(),
      title: '没年月日を選択',
      icon: Icons.event,
    );
    if (picked != null) {
      setState(() => _deathDate = picked);
    }
  }
}
