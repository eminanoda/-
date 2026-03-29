import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models/conuseling_record.dart';
import 'widgets/premium_ai_summary_card.dart';
import 'widgets/premium_feature_card.dart';

class CounselingRecordScreen extends StatefulWidget {
  const CounselingRecordScreen({super.key});

  @override
  State<CounselingRecordScreen> createState() => _CounselingRecordScreenState();
}

class _CounselingRecordScreenState extends State<CounselingRecordScreen> {
  final _clinicController = TextEditingController(text: 'OO美容クリニック 銀座院');
  final _doctorController = TextEditingController(text: '山田 先生');
  final _dateController = TextEditingController(text: '2026 / 03 / 18');
  final _memoController = TextEditingController(
    text: '切開位置、ダウンタイム、麻酔の種類、追加費用の説明あり。',
  );
  String _selectedLanguage = '日本語';
  bool _showPremiumPreview = false;

  @override
  void dispose() {
    _clinicController.dispose();
    _doctorController.dispose();
    _dateController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveRecordAsJson() async {
    final record = CounselingRecord(
      clinic: _clinicController.text.trim(),
      doctor: _doctorController.text.trim(),
      date: _dateController.text.trim(),
      language: _selectedLanguage,
      memo: _memoController.text.trim(),
      isPremium: _showPremiumPreview,
    );

    try {
      await addCounselingRecord(record);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存しました')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $error')));
    }
  }

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
          _FormField(label: 'クリニック名', controller: _clinicController),
          const SizedBox(height: 12),
          _FormField(label: '医師名', controller: _doctorController),
          const SizedBox(height: 12),
          _FormField(label: '日付', controller: _dateController),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            items: const [
              DropdownMenuItem(value: '日本語', child: Text('日本語')),
              DropdownMenuItem(value: '韓国語', child: Text('韓国語')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedLanguage = value;
                });
              }
            },
            decoration: const InputDecoration(labelText: '言語'),
          ),
          const SizedBox(height: 20),
          _FormField(label: 'メモ', maxLines: 5, controller: _memoController),
          const SizedBox(height: 20),
          if (!_showPremiumPreview) ...[
            const _SectionTitle('有料機能'),
            const SizedBox(height: 12),
            PremiumFeatureCard(
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
                  onPressed: _saveRecordAsJson,
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
    this.initialValue = '',
    this.controller,
    this.maxLines = 1,
  });

  final String label;
  final String initialValue;
  final TextEditingController? controller;
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
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          maxLines: maxLines,
        ),
      ],
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
            const PremiumAiSummaryCard(),
          ],
        ),
      ),
    );
  }
}
