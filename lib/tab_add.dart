import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  String? _audioFileName;
  String? _audioDuration;
  String? _transcript;

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
      audioFileName: _audioFileName,
      audioDuration: _audioDuration,
      transcript: _transcript,
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

  void _handleRecordingCompleted(String fileName, String? duration) {
    setState(() {
      _audioFileName = fileName;
      _audioDuration = duration;
    });
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
            _TranscribeCard(
              onRecorded: _handleRecordingCompleted,
              onTranscriptChanged: (transcript) => setState(() {
                _transcript = transcript;
              }),
            ),
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
    this.controller,
    this.maxLines = 1,
  });

  final String label;
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
          initialValue: controller == null ? '' : null,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

class _TranscribeCard extends StatefulWidget {
  const _TranscribeCard({
    required this.onRecorded,
    required this.onTranscriptChanged,
  });

  final void Function(String fileName, String? duration) onRecorded;
  final void Function(String transcript) onTranscriptChanged;

  @override
  State<_TranscribeCard> createState() => _TranscribeCardState();
}

class _TranscribeCardState extends State<_TranscribeCard> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _transcriptController = TextEditingController();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  double _audioLevel = 0;
  Duration _recordDuration = Duration.zero;
  String _durationText = '00:00';
  String? _recordedFileName;
  String? _recordedFilePath;
  String _selectedLanguage = '日本語';
  Timer? _meterTimer;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
    });
    _transcriptController.addListener(() {
      if (!mounted) return;
      widget.onTranscriptChanged(_transcriptController.text);
    });
    _initSpeech();
  }

  @override
  void dispose() {
    _meterTimer?.cancel();
    _durationTimer?.cancel();
    _transcriptController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speechToText.initialize(
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('音声認識の初期化に失敗しました: ${error.errorMsg}')),
        );
      },
      onStatus: (_) {},
    );
    if (!mounted) return;
    setState(() {
      _speechAvailable = available;
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('マイクの許可が必要です。')));
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    _recordedFileName = 'record_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${directory.path}/$_recordedFileName';

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      _recordedFilePath = path;
      _meterTimer?.cancel();
      _durationTimer?.cancel();
      _recordDuration = Duration.zero;
      setState(() {
        _isRecording = true;
        _audioLevel = 0;
        _durationText = '00:00';
      });

      _meterTimer = Timer.periodic(const Duration(milliseconds: 100), (
        _,
      ) async {
        if (!mounted || !_isRecording) return;
        final amplitude = await _recorder.getAmplitude();
        final normalized = (amplitude.current / 120).clamp(0.0, 1.0);
        setState(() {
          _audioLevel = normalized;
        });
      });

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecording) return;
        setState(() {
          _recordDuration += const Duration(seconds: 1);
          _durationText = _formatDuration(_recordDuration);
        });
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('録音の開始に失敗しました: $error')));
    }
  }

  Future<void> _stopRecording() async {
    _meterTimer?.cancel();
    _durationTimer?.cancel();
    try {
      await _recorder.stop();
      if (_recordedFileName != null) {
        widget.onRecorded(_recordedFileName!, _formatDuration(_recordDuration));
      }
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _audioLevel = 0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('録音を停止しました')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('録音の停止に失敗しました: $error')));
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('音声認識が利用できません。')));
      return;
    }

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: _selectedLanguage == '日本語' ? 'ja_JP' : 'ko_KR',
      listenMode: ListenMode.dictation,
      partialResults: true,
    );
    if (!mounted) return;
    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _transcriptController.text = result.recognizedWords;
    });
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty) {
      return;
    }

    final audioFile = result.files.first;
    final fileName = audioFile.name;
    final filePath = audioFile.path;
    if (filePath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('音声ファイルの読み込みに失敗しました。')));
      return;
    }

    setState(() {
      _recordedFileName = fileName;
      _recordedFilePath = filePath;
    });
    widget.onRecorded(fileName, null);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('音声ファイルを追加しました: $fileName')));
  }

  Future<void> _togglePlayback() async {
    final path = _recordedFilePath;
    if (path == null || _isRecording) {
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

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
                    onPressed: _toggleRecording,
                    icon: Icon(
                      _isRecording
                          ? CupertinoIcons.stop_fill
                          : CupertinoIcons.mic,
                    ),
                    label: Text(_isRecording ? '録音停止' : '録音開始'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickAudioFile,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.waveform,
                        color: Color(0xFF5672D9),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isRecording
                              ? '録音中 $_durationText'
                              : _recordedFileName != null
                              ? '追加済み: ${_recordedFileName!}'
                              : '準備完了',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF24365F),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _recordedFilePath != null && !_isRecording
                            ? _togglePlayback
                            : null,
                        icon: Icon(
                          _isPlaying
                              ? CupertinoIcons.pause_circle
                              : CupertinoIcons.play_circle,
                          color: _recordedFilePath != null && !_isRecording
                              ? const Color(0xFF5672D9)
                              : const Color(0xFFB0BEC5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AudioLevelMeter(level: _audioLevel),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _speechAvailable ? _toggleListening : null,
                    icon: Icon(
                      _isListening ? CupertinoIcons.stop_fill : CupertinoIcons.mic_fill,
                    ),
                    label: Text(_isListening ? '停止して保存' : '文字起こし開始'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    items: const [
                      DropdownMenuItem(value: '日本語', child: Text('日本語')),
                      DropdownMenuItem(value: '韓国語', child: Text('韓国語')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedLanguage = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: '文字起こし言語'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormField(
              label: '文字起こし結果',
              maxLines: 6,
              controller: _transcriptController,
            ),
            const SizedBox(height: 14),
            const PremiumAiSummaryCard(),
          ],
        ),
      ),
    );
  }
}

class _AudioLevelMeter extends StatelessWidget {
  const _AudioLevelMeter({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final threshold = (index + 1) / 6;
        final isActive = level >= threshold;
        final barHeight = 8.0 + index * 6.0;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: barHeight,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF5672D9)
                  : const Color(0xFFD5E2F4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
