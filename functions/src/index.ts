import * as speech from '@google-cloud/speech';
import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import Busboy from 'busboy';
import * as path from 'path';
import { randomUUID } from 'crypto';
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
export const transcribeAudio = onRequest({
    cpu: 4,           // 0.08〜8 vCPUの間で設定
    memory: "16GiB",   // 128MiB〜32GiBの間で設定
    region: "us-central1" // デプロイする地域
  },
  async (req: Request, res: Response) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    const busboy = Busboy({
      headers: req.headers,
      limits: {
        files: 1,
        fileSize: 20 * 1024 * 1024,
      },
    });

    let audioBuffer: Buffer | null = null;
    let originalName = 'audio.wav';
    let mimeType = 'audio/wav';
    let language = 'ja-JP';

    busboy.on('field', (fieldname, value) => {
      if (fieldname === 'language') {
        language = value || 'ja-JP';
      }
    });

    busboy.on('file', (fieldname, file, info) => {
      if (fieldname !== 'audio') {
        file.resume();
        return;
      }

      originalName = info.filename || 'audio.wav';
      mimeType = info.mimeType || 'audio/wav';

      const chunks: Buffer[] = [];

      file.on('data', (data) => {
        chunks.push(data);
      });

      file.on('end', () => {
        audioBuffer = Buffer.concat(chunks);
      });
    });

    busboy.on('error', (error) => {
      console.error('Busboy error:', error);
      res.status(500).json({
        message: 'File upload error',
        error: error,
      });
    });

    busboy.on('finish', async () => {
      try {
        if (!audioBuffer) {
          res.status(400).json({ message: 'No audio file provided' });
          return;
        }

        const ext = path.extname(originalName).toLowerCase();
        const bucketName = getDefaultStorageBucketName();

        if (!bucketName) {
          res.status(500).json({ message: 'Storage bucket is not configured' });
          return;
        }

        const bucket = admin.storage().bucket(bucketName);
        const objectName = `transcription-uploads/${randomUUID()}${ext || '.wav'}`;
        const file = bucket.file(objectName);
        const gcsUri = `gs://${bucket.name}/${objectName}`;
        const config = buildRecognitionConfig(language);

        await file.save(audioBuffer, {
          resumable: false,
          contentType: mimeType,
          metadata: {
            cacheControl: 'no-store',
          },
        });

        console.log('transcription.gcsUri:', gcsUri);

        let transcription = '';
        try {
          transcription = await transcribeFromStorageUri(gcsUri, config);
        } finally {
          //todo await file.delete({ ignoreNotFound: true });
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
    });

    const rawBody = (req as Request & { rawBody?: Buffer }).rawBody;

    if (rawBody) {
      busboy.end(rawBody);
    } else {
      req.pipe(busboy);
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
