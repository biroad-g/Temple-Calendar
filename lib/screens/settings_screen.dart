import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // 六曜の定義（表示順）
  static const List<Map<String, dynamic>> _rokuyoDefs = [
    {'name': '大安', 'color': AppTheme.taian, 'desc': 'すべてのことに大吉。何事にも良い日。'},
    {'name': '友引', 'color': AppTheme.tomobiki, 'desc': '友を引く日。慶事に吉、凶事に凶。'},
    {'name': '先勝', 'color': AppTheme.sensho, 'desc': '急ぐことは吉。午前中が吉、午後が凶。'},
    {'name': '先負', 'color': AppTheme.senbu, 'desc': '先を急ぐと凶。午前中が凶、午後が吉。'},
    {'name': '仏滅', 'color': AppTheme.butsumetsu, 'desc': '万事が凶の日。すべてが滅する日。'},
    {'name': '赤口', 'color': AppTheme.shakko, 'desc': '正午のみ吉、それ以外は凶の日。'},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text('⚙️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text(
                      '設定',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── カレンダー設定 ───────────────────────
              _sectionTitle('カレンダー設定'),
              _buildCard(
                child: _settingRow(
                  icon: Icons.auto_awesome,
                  label: '六曜をすべて表示',
                  description: '六曜の表示・非表示をまとめて切り替え',
                  trailing: Switch(
                    value: appState.showRokuyo,
                    onChanged: (_) => appState.toggleRokuyo(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── 六曜 個別ON/OFF ─────────────────────
              _sectionTitle('六曜 個別表示設定'),
              _buildCard(
                child: Column(
                  children: [
                    // 全体がOFFの場合は薄く無効表示
                    if (!appState.showRokuyo)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppTheme.textMuted, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '六曜表示がOFFのため個別設定は無効です',
                              style: TextStyle(
                                color: AppTheme.textMuted.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ..._rokuyoDefs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final def = entry.value;
                      final name = def['name'] as String;
                      final color = def['color'] as Color;
                      final desc = def['desc'] as String;
                      final isVisible =
                          appState.rokuyoVisibility[name] ?? true;
                      final isEnabled = appState.showRokuyo;

                      return Column(
                        children: [
                          if (i > 0) const Divider(color: AppTheme.navyLight, height: 1),
                          AnimatedOpacity(
                            opacity: isEnabled ? 1.0 : 0.4,
                            duration: const Duration(milliseconds: 200),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  // 六曜アイコン
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isVisible && isEnabled
                                          ? color.withValues(alpha: 0.18)
                                          : AppTheme.navyLight
                                              .withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isVisible && isEnabled
                                            ? color.withValues(alpha: 0.6)
                                            : AppTheme.navyLight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          color: isVisible && isEnabled
                                              ? color
                                              : AppTheme.textMuted,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // テキスト
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: isVisible && isEnabled
                                                ? color
                                                : AppTheme.textMuted,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          desc,
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 個別スイッチ
                                  Switch(
                                    value: isVisible,
                                    onChanged: isEnabled
                                        ? (_) =>
                                            appState.toggleIndividualRokuyo(name)
                                        : null,
                                    activeColor: color,
                                    activeTrackColor:
                                        color.withValues(alpha: 0.3),
                                    inactiveThumbColor: AppTheme.textMuted,
                                    inactiveTrackColor:
                                        AppTheme.navyLight,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    // 全選択/全解除ボタン
                    const Divider(color: AppTheme.navyLight, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: appState.showRokuyo
                                ? () => _setAllRokuyo(context, false)
                                : null,
                            icon: const Icon(Icons.visibility_off, size: 14),
                            label: const Text('すべてOFF', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textMuted,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: appState.showRokuyo
                                ? () => _setAllRokuyo(context, true)
                                : null,
                            icon: const Icon(Icons.visibility, size: 14),
                            label: const Text('すべてON', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.gold,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── アプリ情報 ────────────────────────────
              _sectionTitle('アプリ情報'),
              _buildCard(
                child: Column(
                  children: [
                    _infoRow('アプリ名', '寺院カレンダー'),
                    _divider(),
                    _infoRow('バージョン', '1.0.0'),
                    _divider(),
                    _infoRow('対応年範囲', '2000年〜2050年'),
                    _divider(),
                    _infoRow('六曜計算', '旧暦ベース天文算法'),
                    _divider(),
                    _infoRow('和暦対応', '明治・大正・昭和・平成・令和'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── 年忌法要について ──────────────────────
              _sectionTitle('年忌法要について'),
              _buildCard(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '年忌法要の計算方法',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '• 一周忌：命日の翌年\n'
                        '• 三回忌：命日から2年後\n'
                        '• 七回忌：命日から6年後\n'
                        '• 以降は回忌数から1を引いた年数後\n\n'
                        '例）命日が令和5年の場合\n'
                        '  一周忌：令和6年（翌年）\n'
                        '  三回忌：令和7年（2年後）\n'
                        '  七回忌：令和11年（6年後）',
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // コピーライト
              const Center(
                child: Text(
                  '© 2025 Temple Calendar\n仏教寺院向けカレンダーアプリ',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 全六曜をまとめてON/OFFする
  void _setAllRokuyo(BuildContext context, bool value) {
    final appState = context.read<AppState>();
    for (final def in _rokuyoDefs) {
      final name = def['name'] as String;
      final current = appState.rokuyoVisibility[name] ?? true;
      if (current != value) {
        appState.toggleIndividualRokuyo(name);
      }
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.navyLight),
      ),
      child: child,
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String label,
    required String description,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      color: AppTheme.navyLight,
      height: 1,
      indent: 14,
      endIndent: 14,
    );
  }
}
