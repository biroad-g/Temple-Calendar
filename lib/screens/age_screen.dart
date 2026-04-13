import 'package:flutter/material.dart';
import '../services/memorial_service.dart';
import '../services/japanese_calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/wareki_date_picker.dart';

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  DateTime? _birthDate;
  final DateTime _today = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              _buildHeader(),
              const SizedBox(height: 20),
              // 生年月日入力（和暦・西暦対応ピッカー）
              _buildBirthDateInput(),
              const SizedBox(height: 20),
              // 年齢表示（満年齢・数え年）
              if (_birthDate != null) ...[
                _buildAgeCard(),
                const SizedBox(height: 16),
                _buildWarekiCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold, width: 0.5),
      ),
      child: const Row(
        children: [
          Text('🧮', style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '年齢計算',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '満年齢・数え年 ／ 西暦・和暦対応',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '生年月日を入力',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '西暦・和暦（昭和・平成・令和など）どちらでも選択できます',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectBirthDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.navyLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _birthDate != null ? AppTheme.gold : AppTheme.navyLight,
                  width: _birthDate != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake, color: AppTheme.gold, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _birthDate != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_birthDate!.year}年${_birthDate!.month}月${_birthDate!.day}日',
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                JapaneseCalendarService.toJapaneseEra(
                                    _birthDate!.year,
                                    _birthDate!.month,
                                    _birthDate!.day),
                                style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            '生年月日を選択してください\n（西暦 または 和暦で選択可能）',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.gold),
                ],
              ),
            ),
          ),
          if (_birthDate != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _birthDate = null),
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('クリア', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgeCard() {
    if (_birthDate == null) return const SizedBox.shrink();
    final age = MemorialService.calcAge(_birthDate!, _today);
    final kazoeAge = MemorialService.calcKazoeAge(_birthDate!, _today);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold, width: 0.5),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: AppTheme.gold, size: 18),
              SizedBox(width: 8),
              Text(
                '年齢',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ageBox(
                  label: '満年齢',
                  value: '$age歳',
                  description: '誕生日を迎えると1歳加算\n（現在の一般的な年齢）',
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ageBox(
                  label: '数え年',
                  value: '$kazoeAge歳',
                  description: '生まれた年を1歳とし\n元旦（1月1日）に加算',
                  color: AppTheme.goldLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 詳細情報
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.navyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _infoRow(
                  '基準日（本日）',
                  '${_today.year}年${_today.month}月${_today.day}日\n'
                      '（${JapaneseCalendarService.toJapaneseEra(_today.year, _today.month, _today.day)}）',
                ),
                const SizedBox(height: 6),
                _infoRow(
                  '生年月日（西暦）',
                  '${_birthDate!.year}年${_birthDate!.month}月${_birthDate!.day}日',
                ),
                const SizedBox(height: 6),
                _infoRow(
                  '生年月日（和暦）',
                  JapaneseCalendarService.toJapaneseEra(
                      _birthDate!.year, _birthDate!.month, _birthDate!.day),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ageBox({
    required String label,
    required String value,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWarekiCard() {
    if (_birthDate == null) return const SizedBox.shrink();

    // 和暦各元号での年表示
    final eraList = JapaneseCalendarService.getAllErasForYear(_birthDate!.year);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_edu, color: AppTheme.gold, size: 18),
              SizedBox(width: 8),
              Text(
                '和暦・西暦 対応表示',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 生年の西暦・和暦
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.navyLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '生まれ年の和暦',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _eraBox(
                        label: '西暦',
                        value: '${_birthDate!.year}年',
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _eraBox(
                        label: '和暦',
                        value: JapaneseCalendarService.toJapaneseEra(
                            _birthDate!.year,
                            _birthDate!.month,
                            _birthDate!.day),
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 全元号対応表
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.navyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '元号早見表（生まれ年・西暦との対応）',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...eraList.map((era) {
                  final isCurrentEra =
                      era['eraName'] == JapaneseCalendarService.getEraName(
                          _birthDate!.year, _birthDate!.month, _birthDate!.day);
                  return _eraTableRow(era, isCurrentEra);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eraBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.navyDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style:
                const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eraTableRow(Map<String, dynamic> era, bool isCurrentEra) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isCurrentEra ? AppTheme.gold : AppTheme.navyLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              era['eraName'] as String,
              style: TextStyle(
                color:
                    isCurrentEra ? AppTheme.gold : AppTheme.textMuted,
                fontSize: 12,
                fontWeight: isCurrentEra
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '元年 ＝ 西暦${era['startYear']}年',
            style: TextStyle(
              color: isCurrentEra ? AppTheme.textLight : AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          if (isCurrentEra)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
              ),
              child: const Text(
                '該当',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await WarekiDatePicker.show(
      context,
      initialDate: _birthDate ?? DateTime(1960, 1, 1),
      firstDate: DateTime(1868, 10, 23), // 明治元年
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }
}
