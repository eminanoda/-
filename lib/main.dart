import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SurgeryMemoApp());
}

class SurgeryMemoApp extends StatelessWidget {
  const SurgeryMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFF4F7FB);
    const ink = Color(0xFF1D2740);
    const terracotta = Color(0xFF5672D9);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Surgery Memo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: terracotta,
          brightness: Brightness.light,
          surface: base,
        ),
        scaffoldBackgroundColor: base,
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.1,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyLarge: TextStyle(fontSize: 15, color: ink, height: 1.5),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: Color(0xFF5D6885),
            height: 1.45,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7E1F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: terracotta, width: 1.4),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.86),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFDCE5F2)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE3ECFB),
          labelStyle: const TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          side: BorderSide.none,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const RecordsListScreen(),
      const CounselingRecordScreen(),
      const PurchaseScreen(),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAFF), Color(0xFFEAF1FD), Color(0xFFE6F6F4)],
          ),
        ),
        child: Stack(
          children: [
            const _BackgroundGlow(
              alignment: Alignment.topRight,
              color: Color(0xFF8EA7FF),
              size: 240,
            ),
            const _BackgroundGlow(
              alignment: Alignment.centerLeft,
              color: Color(0xFF82D1C8),
              size: 220,
            ),
            SafeArea(child: screens[_index]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 78,
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        indicatorColor: const Color(0xFFDDE7FF),
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.doc_text),
            selectedIcon: Icon(CupertinoIcons.doc_text_fill),
            label: '記録一覧',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.square_pencil),
            selectedIcon: Icon(CupertinoIcons.square_pencil),
            label: '記録作成',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.star_circle),
            selectedIcon: Icon(CupertinoIcons.star_circle_fill),
            label: '有料機能',
          ),
        ],
      ),
    );
  }
}

enum RecordSortOrder { newest, oldest }

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  RecordSortOrder _sortOrder = RecordSortOrder.newest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final records = [...demoRecords]
      ..sort((a, b) {
        final comparison = a.date.compareTo(b.date);
        return _sortOrder == RecordSortOrder.newest ? -comparison : comparison;
      });

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'カウンセリング記録',
                            style: theme.textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '総件数 ${records.length} 件',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD7E1F0)),
                  ),
                  child: _SortToggle(
                    currentValue: _sortOrder,
                    onChanged: (value) {
                      setState(() {
                        _sortOrder = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          sliver: SliverList.separated(
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final record = records[index];
              return _RecordCard(
                record: record,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CounselingRecordDetailScreen(record: record),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CounselingRecordScreen extends StatefulWidget {
  const CounselingRecordScreen({super.key});

  @override
  State<CounselingRecordScreen> createState() => _CounselingRecordScreenState();
}

class _CounselingRecordScreenState extends State<CounselingRecordScreen> {
  bool _showPremiumPreview = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('記録を追加', style: theme.textTheme.displaySmall),

          const SizedBox(height: 20),
          const _SectionTitle('基本情報'),
          const SizedBox(height: 12),
          const _FormField(label: 'クリニック名', initialValue: 'OO美容クリニック 銀座院'),
          const SizedBox(height: 12),
          const _FormField(label: '医師名', initialValue: '山田 先生'),
          const SizedBox(height: 12),
          const _FormField(label: '日付', initialValue: '2026 / 03 / 18'),
          const SizedBox(height: 20),
          const _FormField(
            label: 'メモ',
            maxLines: 5,
            initialValue: '切開位置、ダウンタイム、麻酔の種類、追加費用の説明あり。',
          ),
          const SizedBox(height: 20),
          if (!_showPremiumPreview) ...[
            const _SectionTitle('有料機能'),
            const SizedBox(height: 12),
            _PremiumFeatureCard(
              isPreviewVisible: _showPremiumPreview,
              onUnlockPressed: () {
                setState(() {
                  _showPremiumPreview = !_showPremiumPreview;
                });
              },
            ),
          ] else ...[
            const _PremiumPreviewCard(),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('記録を保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('買い切りプラン', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            '相談中の録音から、文字起こしと要点整理まで一気に残せる拡張機能です。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [Color(0xFF24365F), Color(0xFF2D8C98)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '一度の購入でずっと使える',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Premium Memo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '¥1,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF24365F),
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('購入する'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _PurchaseBenefitTile(
            icon: CupertinoIcons.mic,
            title: '録音',
            description: 'その場で録音開始。既存の音声ファイルアップロードにも対応。',
          ),
          const SizedBox(height: 12),
          const _PurchaseBenefitTile(
            icon: CupertinoIcons.globe,
            title: '文字起こし',
            description: '日本語または韓国語の音声をテキスト化して保存。',
          ),
          const SizedBox(height: 12),
          const _PurchaseBenefitTile(
            icon: CupertinoIcons.sparkles,
            title: 'AI要約',
            description: 'AI を使って診察内容の要点を短く整理。',
          ),
        ],
      ),
    );
  }
}

class CounselingRecordDetailScreen extends StatelessWidget {
  const CounselingRecordDetailScreen({super.key, required this.record});

  final CounselingRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('カウンセリング記録')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailSurface(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.clinic, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${record.doctor}  •  ${record.date}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    /*const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DetailChip(label: record.language),
                        _DetailChip(
                          label: record.audioDuration == null
                              ? '音声なし'
                              : '録音 ${record.audioDuration}',
                        ),
                      ],
                    ),*/
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _DetailSection(
              title: '録音',
              child:  (record.audioFileName == null) ? _UnavailableBlock(
                          icon: CupertinoIcons.mic_slash,
                          text: 'この記録には音声ファイルがありません。',
                        ) : Column(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AudioPlaybackCard(record: record),
                  _PremiumAiSummaryCard(),
                  Text('文字起こし', style: theme.textTheme.titleMedium),
                  record.transcript == null
                      ? const _UnavailableBlock(
                          icon: CupertinoIcons.text_bubble,
                          text: '文字起こしは未保存です。',
                        )
                      : Text(
                          record.transcript!,
                          style: theme.textTheme.bodyLarge,
                        ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DetailSection(
              title: 'メモ',
              child: Text(record.memo, style: theme.textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onTap});

  final CounselingRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.clinic, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          '${record.doctor}  •  ${record.date}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
                    color: Color(0xFF61708E),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(record.memo, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(CupertinoIcons.pencil),
                      label: const Text('編集'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: const Color(0xFF24365F),
                        side: const BorderSide(color: Color(0xFFD2DFF0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {},
                      icon: const Icon(CupertinoIcons.delete),
                      label: const Text('削除'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color.fromARGB(
                          255,
                          255,
                          235,
                          230,
                        ),
                        foregroundColor: const Color.fromARGB(255, 184, 53, 53),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _DetailSurface(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailSurface extends StatelessWidget {
  const _DetailSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE5F2)),
      ),
      child: child,
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF24365F),
        ),
      ),
    );
  }
}

class _AudioPlaybackCard extends StatelessWidget {
  const _AudioPlaybackCard({required this.record});

  final CounselingRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E2F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.waveform, color: Color(0xFF5672D9)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ''/*record.audioFileName!*/,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF24365F),
                  ),
                ),
              ),
              const Icon(CupertinoIcons.play_circle_fill, size: 28),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.42,
              minHeight: 8,
              backgroundColor: Color(0xFFDCE8FB),
              valueColor: AlwaysStoppedAnimation(Color(0xFF5672D9)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '00:53 / ${record.audioDuration}',
            style: const TextStyle(
              color: Color(0xFF61708E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableBlock extends StatelessWidget {
  const _UnavailableBlock({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E2F1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF61708E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.currentValue, required this.onChanged});

  final RecordSortOrder currentValue;
  final ValueChanged<RecordSortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SortToggleItem(
            label: '新しい順',
            isSelected: currentValue == RecordSortOrder.newest,
            onTap: () => onChanged(RecordSortOrder.newest),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SortToggleItem(
            label: '古い順',
            isSelected: currentValue == RecordSortOrder.oldest,
            onTap: () => onChanged(RecordSortOrder.oldest),
          ),
        ),
      ],
    );
  }
}

class _SortToggleItem extends StatelessWidget {
  const _SortToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? const Color(0xFF5672D9) : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF5672D9).withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF24365F),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  const _PremiumFeatureCard({
    required this.isPreviewVisible,
    required this.onUnlockPressed,
  });

  final bool isPreviewVisible;
  final VoidCallback onUnlockPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const _PremiumRow(
              icon: CupertinoIcons.mic,
              title: 'その場で録音',
              text: '診察中にそのままレコーディング開始。',
            ),
            const Divider(height: 28),
            const _PremiumRow(
              icon: CupertinoIcons.arrow_up_doc,
              title: '音声ファイルアップロード',
              text: 'あとから保存済みファイルを取り込み可能。',
            ),
            const Divider(height: 28),
            const _PremiumRow(
              icon: CupertinoIcons.text_bubble,
              title: '日本語 / 韓国語 文字起こし',
              text: '録音内容を読める形で残す。',
            ),
            const Divider(height: 28),
            const _PremiumRow(
              icon: CupertinoIcons.sparkles,
              title: 'AI要約',
              text: '費用、術式、注意点を要約。',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onUnlockPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE2ECFF),
                  foregroundColor: const Color(0xFF24365F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isPreviewVisible ? '有料機能UIを閉じる' : '有料機能をアンロック'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumPreviewCard extends StatelessWidget {
  const _PremiumPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(CupertinoIcons.mic),
                    label: const Text('録音開始'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(CupertinoIcons.arrow_up_doc),
                    label: const Text('音声を追加'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: const Color(0xFF24365F),
                      side: const BorderSide(color: Color(0xFFD2DFF0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD5E2F4)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.waveform, color: Color(0xFF5672D9)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '32:48',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF24365F),
                      ),
                    ),
                  ),
                  Icon(CupertinoIcons.play_circle),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: '日本語',
              items: const [
                DropdownMenuItem(value: '日本語', child: Text('日本語')),
                DropdownMenuItem(value: '韓国語', child: Text('韓国語')),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(labelText: '文字起こし言語'),
            ),
            const SizedBox(height: 14),
            const _FormField(
              label: '文字起こし結果',
              maxLines: 6,
              initialValue:
                  '先生: ダウンタイムは1週間ほどです。腫れのピークは2日目で、抜糸は7日後になります。費用は麻酔代込みでの案内です。',
            ),
            const SizedBox(height: 14),
            const _PremiumAiSummaryCard(),
          ],
        ),
      ),
    );
  }
}

class _PremiumAiSummaryCard extends StatelessWidget {
  const _PremiumAiSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF24365F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: Color(0xFF9FE7E0), size: 18),
              SizedBox(width: 8),
              Text(
                'AI要約',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '・腫れのピークは術後2日目\n・抜糸は7日後\n・費用は麻酔代込み\n・大事な予定は1週間後以降が無難',
            style: TextStyle(color: Color(0xFFE9F1FF), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PremiumRow extends StatelessWidget {
  const _PremiumRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF24365F)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1D2740),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(color: Color(0xFF61708E), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseBenefitTile extends StatelessWidget {
  const _PurchaseBenefitTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F4F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF245A68)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.initialValue,
    this.maxLines = 1,
  });

  final String label;
  final String initialValue;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(initialValue: initialValue, maxLines: maxLines),
      ],
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CounselingRecord {
  const CounselingRecord({
    required this.clinic,
    required this.doctor,
    required this.date,
    required this.language,
    required this.memo,
    required this.isPremium,
    this.audioFileName,
    this.audioDuration,
    this.transcript,
    this.aiSummary,
  });

  final String clinic;
  final String doctor;
  final String date;
  final String language;
  final String memo;
  final bool isPremium;
  final String? audioFileName;
  final String? audioDuration;
  final String? transcript;
  final String? aiSummary;
}

const demoRecords = [
  CounselingRecord(
    clinic: 'OO美容クリニック 銀座院',
    doctor: '山田 先生',
    date: '2026.03.18',
    language: '日本語',
    memo: '埋没と切開の違い、ダウンタイム、抜糸までの流れを確認。',
    isPremium: false,
  ),
  CounselingRecord(
    clinic: 'Lumi Skin Clinic',
    doctor: 'Kim Dr.',
    date: '2026.03.10',
    language: '韓国語',
    memo: '脂肪吸引の適応範囲と見積もりの内訳を確認。麻酔代は別。',
    isPremium: true,
    audioFileName: 'lumi_consult_20260310.m4a',
    audioDuration: '12:48',
    transcript: '医師: 目頭切開は0.5mm単位で調整できます。腫れは1週間程度で、抜糸は5日後です。費用には麻酔代が含まれます。',
    aiSummary: '・目頭切開は細かく調整可能\n・腫れは約1週間\n・抜糸は5日後\n・見積もりは麻酔代込み',
  ),
  CounselingRecord(
    clinic: 'Miel美容外科',
    doctor: '佐藤 先生',
    date: '2026.02.28',
    language: '日本語',
    memo: '脂肪吸引の適応範囲と見積もりの内訳を確認。麻酔代は別。',
    isPremium: true,
    audioFileName: 'miel_followup_20260228.m4a',
    audioDuration: '08:15',
    transcript: '先生: 頬下とフェイスラインを中心に吸引します。固定バンドは3日ほどしっかり着用し、内出血は2週間ほど見てください。',
    aiSummary: '・頬下とフェイスライン中心\n・固定バンドは術後3日が目安\n・内出血は約2週間\n・麻酔代は別見積もり',
  ),
];
