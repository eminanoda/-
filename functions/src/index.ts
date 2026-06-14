import * as speech from '@google-cloud/speech';
import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

admin.initializeApp();

// Speech-to-Text v2 API。リージョナルエンドポイント経由で利用する。
const PROJECT_ID = 'surgery-counselling-memo';
const SPEECH_LOCATION = 'us-central1';
// chirp_2 は us-central1 で ja-JP / ko-KR をサポートする多言語モデル。
// 'long' は global ロケーションでしか日本語に対応していないため使用しない。
const SPEECH_MODEL = 'chirp_2';
const RECOGNIZER = `projects/${PROJECT_ID}/locations/${SPEECH_LOCATION}/recognizers/_`;

const client = new speech.v2.SpeechClient({
  apiEndpoint: `${SPEECH_LOCATION}-speech.googleapis.com`,
});
const geminiModel = 'gemini-2.5-flash';
const geminiApiKey = defineSecret('GEMINI_API_KEY');

// クライアントが音声を直接アップロードする Storage 配下のプレフィックス。
const UPLOAD_PREFIX = 'transcription-uploads';

function getDefaultStorageBucketName(): string | undefined {

  return 'surgery-counselling-memo.firebasestorage.app';
}

function buildRecognitionConfig(
  language: string,
): speech.protos.google.cloud.speech.v2.IRecognitionConfig {
  return {
    // エンコーディング/サンプルレートは音声ヘッダから自動判定させる。
    autoDecodingConfig: {},
    languageCodes: [language],
    model: SPEECH_MODEL,
    features: {
      enableAutomaticPunctuation: true,
    },
  };
}

async function transcribeFromStorageUri(
  gcsUri: string,
  config: speech.protos.google.cloud.speech.v2.IRecognitionConfig,
): Promise<string> {
  const [operation] = await client.batchRecognize({
    recognizer: RECOGNIZER,
    config,
    files: [{ uri: gcsUri }],
    recognitionOutputConfig: {
      inlineResponseConfig: {},
    },
  });
  const [response] = await operation.promise();
  console.log('response.results:', response.results);

  const fileResult = response.results?.[gcsUri];

  return (
    fileResult?.transcript?.results
      ?.map((result) => result.alternatives?.[0]?.transcript)
      .filter(Boolean)
      .join(' ') || ''
  );
}

function buildAiSummaryPrompt(transcript: string, language: string): string {
  const outputLanguage = language === 'ko-KR' ? 'Korean' : 'Japanese';
  return `
You are assisting with a cosmetic surgery counseling note.
Summarize the following transcript in ${outputLanguage}.

## Constraints:
- **Output ONLY the summary.** No introductions or conclusions.
- Use simple bullet points. Do not invent facts.

Transcript:
${transcript}
`.trim();
}

// https://console.cloud.google.com/run/detail/us-central1/transcribeaudio/observability/logs?project=surgery-counselling-memo
export const transcribeAudioFromStorage = onRequest({
    cpu: 4,           // 0.08〜8 vCPUの間で設定
    memory: "16GiB",   // 128MiB〜32GiBの間で設定
    region: "us-central1" // デプロイする地域
  },
  async (req: Request, res: Response) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    try {
      // クライアントが Storage へ直接アップロード済みの音声を gs:// URI で受け取る。
      const gcsUri = typeof req.body?.gcsUri === 'string' ? req.body.gcsUri.trim() : '';
      const language =
        typeof req.body?.language === 'string' ? req.body.language : 'ja-JP';

      const bucketName = getDefaultStorageBucketName();
      if (!bucketName) {
        res.status(500).json({ message: 'Storage bucket is not configured' });
        return;
      }

      // 任意のオブジェクトを文字起こしさせないよう、想定パスのみ許可する。
      const allowedPrefix = `gs://${bucketName}/${UPLOAD_PREFIX}/`;
      if (!gcsUri.startsWith(allowedPrefix)) {
        res.status(400).json({ message: 'Invalid or missing gcsUri' });
        return;
      }

      const objectName = gcsUri.slice(`gs://${bucketName}/`.length);
      const config = buildRecognitionConfig(language);

      console.log('transcription.gcsUri:', gcsUri);

      const file = admin.storage().bucket(bucketName).file(objectName);

      let transcription = '';
      try {
        transcription = await transcribeFromStorageUri(gcsUri, config);
      } finally {
        // 文字起こし後は一時音声を破棄する。
        await file.delete({ ignoreNotFound: true });
      }

      console.log('transcription:', transcription);

      res.status(200).json({ transcript: transcription });
    } catch (error: any) {
      console.error('Error transcribing audio:', error);
      res.status(500).json({
        message: 'Error transcribing audio',
        error: error.message,
        code: error.code,
        details: error.details,
      });
    }
  }
);

export const summarizeCounseling = onRequest(
  { secrets: [geminiApiKey] },
  async (req: Request, res: Response) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    try {
      const transcript =
        typeof req.body?.transcript === 'string' ? req.body.transcript.trim() : '';
      const language = typeof req.body?.language === 'string' ? req.body.language : 'ja-JP';
      const apiKey = geminiApiKey.value();

      if (!transcript) {
        res.status(400).json({ error: 'Transcript is required' });
        return;
      }
      if (!apiKey) {
        res.status(400).json({ error: 'apiKey is required' });
        return;
      }

      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: JSON.stringify({
            contents: [
              {
                parts: [{ text: buildAiSummaryPrompt(transcript, language) }],
              },
            ],
          }),
        },
      );

      const responseText = await response.text();
      if (!response.ok) {
        console.error('Gemini summarize error:', response.status, responseText);
        res.status(502).json({ error: 'Failed to generate summary' + responseText });
        return;
      }

      const data = JSON.parse(responseText) as {
        candidates?: Array<{
          content?: {
            parts?: Array<{ text?: string }>;
          };
        }>;
      };
      const summary = data.candidates?.[0]?.content?.parts
        ?.map((part) => part.text ?? '')
        .join('\n')
        .trim();

      if (!summary) {
        res.status(502).json({ error: 'Empty summary from Gemini' });
        return;
      }

      res.status(200).json({ summary });
    } catch (error) {
      console.error('Error summarizing transcript:', error);
      res.status(500).json({ error: 'Error summarizing transcript' });
    }
  },
);
