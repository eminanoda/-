import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloud Run endpoint for the speech-to-text service.
const String cloudRunUrl = 'https://us-central1-surgery-counselling-memo.cloudfunctions.net/transcribeAudioFromStorage';
/**
 * TEST:
 * curl -X POST "https://us-central1-surgery-counselling-memo.cloudfunctions.net/transcribeAudioFromStorage" \
     -H "Content-Type: application/json" \
     -d '{"gcsUri": "ここにGCSのURI", "language": "ja-JP"}'
 */

/// Cloud Functions endpoint for the AI summary service.
final Uri _summaryFunctionUri = Uri.parse(
  'https://us-central1-surgery-counselling-memo.cloudfunctions.net/summarizeCounseling',
);

/// Maps the in-app language label to the API locale code.
String languageCode(String language) => language == '韓国語' ? 'ko-KR' : 'ja-JP';

/*// Transcribes the audio file at [filePath] using the Cloud Run service.
///
/// Returns the recognized transcript, or `null` when the response did not
/// contain transcript text. Throws on network or HTTP failures so callers can
/// surface an error to the user.
Future<String?> transcribeAudioFromStorageFile(
  String filePath,
  String language,
) async {
  final request = http.MultipartRequest('POST', Uri.parse(cloudRunUrl));

  request.files.add(
    await http.MultipartFile.fromPath(
      'audio',
      filePath,
      filename: filePath.split('/').last,
      contentType: MediaType('audio', 'wav'),
    ),
  );
  request.fields['language'] = languageCode(language);

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode != 200) {
    debugPrint(
      'transcribeAudioFromStorageFile failed: ${response.statusCode} $responseBody',
    );
    throw Exception('Failed to transcribe: ${response.statusCode}');
  }

  final decoded = json.decode(responseBody) as Map<String, dynamic>;
  final transcript = decoded['transcript'];
  if (transcript is! String) {
    return null;
  }
  final text = transcript.trim();
  return text.isEmpty ? null : text;
}
*/
/// Requests an AI summary for [transcript] from the Cloud Functions service.
///
/// Returns the summary text, or `null` when the response did not contain a
/// non-empty summary. Throws on network or HTTP failures.
Future<String?> fetchAiSummary(String transcript, String language) async {
  final response = await http.post(
    _summaryFunctionUri,
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'transcript': transcript,
      'language': languageCode(language),
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    debugPrint(
      'fetchAiSummary httpError ${response.statusCode} ${response.body}',
    );
    throw Exception('AI summary failed: ${response.statusCode}');
  }

  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  debugPrint('decoded $decoded');
  final summary = decoded['summary'];
  if (summary is! String) {
    return null;
  }
  final text = summary.trim();
  return text.isEmpty ? null : text;
}
