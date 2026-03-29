import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'models/conuseling_record.dart';
import 'widgets/premium_ai_summary_card.dart';

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
              child: (record.audioFileName == null)
                  ? _UnavailableBlock(
                      icon: CupertinoIcons.mic_slash,
                      text: 'この記録には音声ファイルがありません。',
                    )
                  : Column(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AudioPlaybackCard(record: record),
                        PremiumAiSummaryCard(summary: record.aiSummary),
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
                  '' /*record.audioFileName!*/,
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
