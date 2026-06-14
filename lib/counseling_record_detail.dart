import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'models/conuseling_record.dart';
import 'services/transcription_service.dart';
import 'tab_add.dart';
import 'widgets/premium_ai_summary_card.dart';

class CounselingRecordDetailScreen extends StatefulWidget {
  const CounselingRecordDetailScreen({
    super.key,
    required this.record,
    this.recordIndex,
  });

  final CounselingRecord record;
  final int? recordIndex;

  @override
  State<CounselingRecordDetailScreen> createState() =>
      _CounselingRecordDetailScreenState();
}

class _CounselingRecordDetailScreenState
    extends State<CounselingRecordDetailScreen> {
  late CounselingRecord _record;
  bool _isSummarizing = false;
  TranscriptionStage _transcriptionStage = TranscriptionStage.idle;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  bool get _canPersist => widget.recordIndex != null;

  bool get _hasAudioFile {
    return _record.audioFileName != null;
  }

  bool get _hasTranscript => _record.transcript?.trim().isNotEmpty ?? false;

  Future<void> _persist(CounselingRecord updated) async {
    setState(() {
      _record = updated;
    });
    if (!_canPersist) return;
    try {
      await updateCounselingRecordAt(widget.recordIndex!, updated);
    } catch (error) {
      if (!mounted) return;
      _alert('保存に失敗しました', '$error');
    }
  }

  Future<String?> _transcribeAudioFromStorageFile(
    String filePath,
    String language,
  ) async {
    setState(() {
      _transcriptionStage = TranscriptionStage.uploading;
      _uploadProgress = 0;
    });
    try {
      // 1. 音声を Firebase Storage へ直接アップロードする(Cloud Run を経由しない)。
      final gcsUri = await _uploadAudioToStorage(filePath);

      // 2. Cloud Run へは gs:// URI のみ JSON で渡し、文字起こしを依頼する。
      if (mounted) {
        setState(() {
          _transcriptionStage = TranscriptionStage.transcribing;
        });
      }
      final response = await http.post(
        Uri.parse(cloudRunUrl),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'gcsUri': gcsUri,
          'language': language == '日本語' ? 'ja-JP' : 'ko-KR',
        }),
      );

      if (!mounted) return null;
      setState(() {
        _transcriptionStage = TranscriptionStage.idle;
      });

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['transcript'];
      } else {
        debugPrint('transcribe failed: ${response.statusCode}');
        debugPrint('body: ${response.body}');
        throw Exception(
          'Failed to transcribe: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!mounted) return null;
      debugPrint('eee $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('文字起こしに失敗しました: $e')));

      setState(() {
        _transcriptionStage = TranscriptionStage.idle;
      });

      return null;
    }
  }

  /// 音声ファイルを `transcription-uploads/{uid}/{fileName}` へアップロードし、
  /// 文字起こし用の gs:// URI を返す。
  Future<String> _uploadAudioToStorage(String filePath) async {
    var user = FirebaseAuth.instance.currentUser;
    user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
    final uid = user!.uid;

    final fileName = filePath.split('/').last;
    final ext = fileName.contains('.') ? fileName.split('.').last : 'wav';
    final objectPath = 'transcription-uploads/$uid/$fileName';
    final ref = FirebaseStorage.instance.ref(objectPath);

    final uploadTask = ref.putFile(
      File(filePath),
      SettableMetadata(contentType: 'audio/$ext'),
    );

    // アップロードの進捗を 0.0〜1.0 で UI に反映する。
    final progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
      if (!mounted || snapshot.totalBytes <= 0) return;
      setState(() {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });

    try {
      await uploadTask;
    } finally {
      await progressSubscription.cancel();
    }

    return 'gs://${ref.bucket}/$objectPath';
  }

  Future<void> _regenerateSummary() async {
    final transcript = _record.transcript;
    if (transcript == null || transcript.trim().isEmpty) {
      _alert('先に文字起こしを作成してください。', '');
      return;
    }

    setState(() {
      _isSummarizing = true;
    });
    try {
      final summary = await fetchAiSummary(transcript, _record.language);
      if (!mounted) return;
      if (summary == null || summary.trim().isEmpty) {
        _alert('要約エラー', '要約結果が空です。');
        return;
      }
      await _persist(_record.copyWith(aiSummary: summary));
      if (!mounted) return;
      _alert('AI要約を更新しました', '');
    } catch (error) {
      if (!mounted) return;
      _alert('AI要約に失敗しました', '$error');
    } finally {
      if (mounted) {
        setState(() {
          _isSummarizing = false;
        });
      }
    }
  }

  void _alert(String title, String descrption) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(descrption),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = _record;
    final isBusy =
        _transcriptionStage != TranscriptionStage.idle || _isSummarizing;

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
                        if (_isSummarizing)
                          const _ProgressRow(label: 'AI要約を作成中です')
                        else
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
                        if (_transcriptionStage != TranscriptionStage.idle)
                          TranscriptionProgress(
                            stage: _transcriptionStage,
                            uploadProgress: _uploadProgress,
                          )
                        else
                          FilledButton.icon(
                            onPressed: (isBusy || !_hasAudioFile)
                                ? null
                                : () async {
                                    var filePath = await record.audioFilePath();
                                    print('filePath $filePath');
                                    var transcript =await
                                        _transcribeAudioFromStorageFile(
                                          filePath!,
                                          record.language,
                                        );
                                    if (transcript != null) {
                                      await _persist(
                                        _record.copyWith(
                                          transcript: transcript,
                                        ),
                                      );
                                      _regenerateSummary();
                                    }
                                  },
                            icon: const Icon(CupertinoIcons.arrow_clockwise),
                            label: Text(
                              '文字起こし / AI要約を${_hasTranscript ? '再' : ''}実行',
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            _DetailSection(
              title: 'メモ',
              child: Text(
                record.memo.isEmpty ? 'メモがありません' : record.memo,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
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

  bool get _hasAudioPath => widget.record.audioFileName != null;

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
    try {
      if (widget.record.audioDuration != null) {
        _duration = parseDuration(widget.record.audioDuration!);
      }
    } catch (e) {
      debugPrint('failed to parse ${widget.record.audioDuration}');
    }
  }

  Duration parseDuration(String value) {
    final parts = value.split(':');

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    return Duration(hours: hours, minutes: minutes);
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
    final path = await widget.record.audioFilePath();
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
                onPressed: _hasAudioPath ? _togglePlayback : null,
                icon: Icon(
                  _isPlaying
                      ? CupertinoIcons.pause_circle_fill
                      : CupertinoIcons.play_circle_fill,
                  size: 28,
                  color: _hasAudioPath
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
            _hasAudioPath
                ? '${_formatDuration(_position)} / ${widget.record.audioDuration}'
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
