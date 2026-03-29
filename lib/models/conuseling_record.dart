import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CounselingRecord {
  const CounselingRecord({
    required this.clinic,
    required this.doctor,
    required this.date,
    required this.language,
    required this.memo,
    required this.isPremium,
    this.audioFileName,
    this.audioFilePath,
    this.audioDuration,
    this.transcript,
    this.aiSummary,
  });

  Map<String, dynamic> toJson() => {
    'clinic': clinic,
    'doctor': doctor,
    'date': date,
    'language': language,
    'memo': memo,
    'isPremium': isPremium,
    if (audioFileName != null) 'audioFileName': audioFileName,
    if (audioFilePath != null) 'audioFilePath': audioFilePath,
    if (audioDuration != null) 'audioDuration': audioDuration,
    if (transcript != null) 'transcript': transcript,
    if (aiSummary != null) 'aiSummary': aiSummary,
  };

  factory CounselingRecord.fromJson(Map<String, dynamic> json) {
    return CounselingRecord(
      clinic: json['clinic'] as String,
      doctor: json['doctor'] as String,
      date: json['date'] as String,
      language: json['language'] as String,
      memo: json['memo'] as String,
      isPremium: json['isPremium'] as bool,
      audioFileName: json['audioFileName'] as String?,
      audioFilePath: json['audioFilePath'] as String?,
      audioDuration: json['audioDuration'] as String?,
      transcript: json['transcript'] as String?,
      aiSummary: json['aiSummary'] as String?,
    );
  }

  final String clinic;
  final String doctor;
  final String date;
  final String language;
  final String memo;
  final bool isPremium;
  final String? audioFileName;
  final String? audioFilePath;
  final String? audioDuration;
  final String? transcript;
  final String? aiSummary;
}

const _recordsStorageFileName = 'counseling_records.json';

final counselingRecordsNotifier = ValueNotifier<List<CounselingRecord>>([]);

Future<File> _getRecordsFile() async {
  final directory = await getApplicationDocumentsDirectory();
  return File('${directory.path}/$_recordsStorageFileName');
}

Future<List<CounselingRecord>> loadCounselingRecords() async {
  try {
    final file = await _getRecordsFile();
    if (!await file.exists()) {
      return [];
    }
    final content = await file.readAsString();
    final jsonList = jsonDecode(content) as List<dynamic>;
    return jsonList
        .map((item) => CounselingRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> saveCounselingRecords(List<CounselingRecord> records) async {
  final file = await _getRecordsFile();
  final jsonString = jsonEncode(
    records.map((record) => record.toJson()).toList(),
  );
  await file.writeAsString(jsonString);
}

Future<void> initializeCounselingRecords() async {
  counselingRecordsNotifier.value = await loadCounselingRecords();
}

Future<void> addCounselingRecord(CounselingRecord record) async {
  final records = await loadCounselingRecords();
  records.add(record);
  await saveCounselingRecords(records);
  counselingRecordsNotifier.value = records;
}
