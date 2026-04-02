import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/conuseling_record.dart';
import 'widgets/premium_ai_summary_card.dart';
import 'widgets/premium_feature_card.dart';

class CounselingRecordScreen extends StatefulWidget {
  const CounselingRecordScreen({super.key});

  @override
  State<CounselingRecordScreen> createState() => _CounselingRecordScreenState();
}

class _CounselingRecordScreenState extends State<CounselingRecordScreen> {
  final _clinicController = TextEditingController(text: '');
  final _doctorController = TextEditingController(text: '');
  final _dateController = TextEditingController(text: '2026 / 03 / 18');
  final _memoController = TextEditingController(text: '');
  String _selectedLanguage = '日本語';
  bool _showPremiumPreview = false;
  String? _audioFileName;
  String? _audioFilePath;
  String? _audioDuration;
  String? _transcript;
  String? _aiSummary;

  @override
  void dispose() {
    _clinicController.dispose();
    _doctorController.dispose();
    _dateController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), '').replaceAll('/', '-');
    return DateTime.tryParse(normalized);
  }

  Future<void> _selectDate() async {
    final initialDate = _parseDate(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ja'),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _dateController.text =
          '${picked.year.toString().padLeft(4, "0")} / '
          '${picked.month.toString().padLeft(2, "0")} / '
          '${picked.day.toString().padLeft(2, "0")}';
    });
  }

  Future<void> _saveRecordAsJson() async {
    String? aiSummary;
    if (_transcript != null && _transcript!.trim().isNotEmpty) {
      aiSummary = await _fetchAiSummary(_transcript!);
      aiSummary ??= _generateAiSummary(_transcript!);
    }
    setState(() {
      _aiSummary = aiSummary;
    });

    final record = CounselingRecord(
      clinic: _clinicController.text.trim(),
      doctor: _doctorController.text.trim(),
      date: _dateController.text.trim(),
      language: _selectedLanguage,
      memo: _memoController.text.trim(),
      isPremium: _showPremiumPreview,
      audioFileName: _audioFileName,
      audioFilePath: _audioFilePath,
      audioDuration: _audioDuration,
      transcript: _transcript,
      aiSummary: aiSummary,
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

  void _handleRecordingCompleted(
    String fileName,
    String? duration,
    String? path,
  ) {
    setState(() {
      _audioFileName = fileName;
      _audioFilePath = path;
      _audioDuration = duration;
    });
  }

  Future<String?> _fetchAiSummary(String transcript) async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }

      final firebaseAI = FirebaseAI.googleAI(auth: auth);
      final model = firebaseAI.generativeModel(model: 'gemini-1.5');
      final prompt = _buildAiSummaryPrompt(transcript);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (_) {
      return null;
    }
  }

  String _buildAiSummaryPrompt(String transcript) {
    final language = _selectedLanguage == '韓国語' ? 'Korean' : 'Japanese';
    return 'Summarize the following counseling transcript in $language:\n\n$transcript';
  }

  String _generateAiSummary(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      return '';
    }

    final sentenceCandidates = cleaned
        .split(RegExp(r'[。！？\n]+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (sentenceCandidates.isEmpty) {
      return cleaned.length <= 120 ? cleaned : '${cleaned.substring(0, 120)}…';
    }

    final bullets = <String>[];
    for (final sentence in sentenceCandidates) {
      if (bullets.length >= 4) break;
      final item =
          sentence.endsWith('。') ||
              sentence.endsWith('！') ||
              sentence.endsWith('？')
          ? sentence
          : '$sentence。';
      bullets.add(item);
    }

    return bullets.join('\n');
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
          TextFormField(
            controller: _dateController,
            readOnly: true,
            decoration: const InputDecoration(labelText: '日付'),
            onTap: _selectDate,
          ),
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
            if (_aiSummary != null) ...[
              const SizedBox(height: 14),
              PremiumAiSummaryCard(summary: _aiSummary),
            ],
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
  const _FormField({required this.label, this.controller, this.maxLines = 1});

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

  final void Function(String fileName, String? duration, String? filePath)
  onRecorded;
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
        widget.onRecorded(
          _recordedFileName!,
          _formatDuration(_recordDuration),
          _recordedFilePath,
        );
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

    final directory = await getApplicationDocumentsDirectory();
    final savedFileName =
        'picked_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final destinationPath = '${directory.path}/$savedFileName';
    try {
      await File(filePath).copy(destinationPath);
      _recordedFilePath = destinationPath;
    } catch (_) {
      _recordedFilePath = filePath;
    }
    setState(() {
      _recordedFileName = fileName;
    });
    widget.onRecorded(fileName, null, _recordedFilePath);
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
                      _isListening
                          ? CupertinoIcons.stop_fill
                          : CupertinoIcons.mic_fill,
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
