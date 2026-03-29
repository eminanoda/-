import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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

class _AudioPlaybackCard extends StatefulWidget {
  const _AudioPlaybackCard({required this.record});

  final CounselingRecord record;

  @override
  State<_AudioPlaybackCard> createState() => _AudioPlaybackCardState();
}

class _AudioPlaybackCardState extends State<_AudioPlaybackCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool get _hasAudioPath => widget.record.audioFilePath != null;
  bool get _fileExists =>
      _hasAudioPath && File(widget.record.audioFilePath!).existsSync();

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
    _player.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _duration = duration;
      });
    });
    _player.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        _position = position;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _togglePlayback() async {
    final path = widget.record.audioFilePath;
    if (path == null || !File(path).existsSync()) {
      return;
    }
    if (_isPlaying) {
      await _player.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    await _player.play(DeviceFileSource(path));
    setState(() {
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

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
                  widget.record.audioFileName ?? '音声ファイル',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF24365F),
                  ),
                ),
              ),
              IconButton(
                onPressed: _fileExists ? _togglePlayback : null,
                icon: Icon(
                  _isPlaying
                      ? CupertinoIcons.pause_circle_fill
                      : CupertinoIcons.play_circle_fill,
                  size: 28,
                  color: _fileExists
                      ? const Color(0xFF5672D9)
                      : const Color(0xFFB0BEC5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFDCE8FB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF5672D9)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _fileExists
                ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                : widget.record.audioDuration != null
                ? '再生準備済み: ${widget.record.audioDuration}'
                : '再生準備中',
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
