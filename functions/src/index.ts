import * as functions from 'firebase-functions';
import * as speech from '@google-cloud/speech';
import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import multer from 'multer';
import * as path from 'path';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

declare global {
  namespace Express {
    interface Request {
      file?: Express.Multer.File;
    }
  }
}

admin.initializeApp();

const client = new speech.SpeechClient();
const upload = multer({ storage: multer.memoryStorage() });
const geminiModel = 'gemini-2.5-flash';
const geminiApiKey = defineSecret('GEMINI_API_KEY');

function getEncodingFromExtension(ext: string): speech.protos.google.cloud.speech.v1.RecognitionConfig.AudioEncoding {
  switch (ext.toLowerCase()) {
    case '.wav':
      return speech.protos.google.cloud.speech.v1.RecognitionConfig.AudioEncoding.LINEAR16;
    case '.flac':
      return speech.protos.google.cloud.speech.v1.RecognitionConfig.AudioEncoding.FLAC;
    case '.mp3':
      return speech.protos.google.cloud.speech.v1.RecognitionConfig.AudioEncoding.MP3;
    case '.ogg':
      return speech.protos.google.cloud.speech.v1.RecognitionConfig.AudioEncoding.OGG_OPUS;
    default:
      return speech.protos.google.cloud.speech.v1.RecognitionConfig.AudioEncoding.LINEAR16;
  }
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

export const transcribeAudio = functions.https.onRequest((req: Request, res: Response) => {
  upload.single('audio')(req, res, async (err: any) => {
    if (err) {
      res.status(500).send('File upload error');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    try {
      const file = req.file;
      const language = req.body.language || 'ja-JP';

      if (!file) {
        res.status(400).send('No audio file provided');
        return;
      }

      const audioBytes = file.buffer;
      const ext = path.extname(file.originalname);
      const encoding = getEncodingFromExtension(ext);

      const audio = {
        content: audioBytes.toString('base64'),
      };

      const config = {
        encoding: encoding,
        languageCode: language,
      };

      const request = {
        audio: audio,
        config: config,
      };

      const [response] = await client.recognize(request);
      const transcription = response.results
        ?.map((result: speech.protos.google.cloud.speech.v1.ISpeechRecognitionResult) => result.alternatives?.[0]?.transcript)
        .join(' ') || '';

      res.status(200).json({ transcript: transcription });
    } catch (error) {
      console.error('Error transcribing audio:', error);
      res.status(500).send('Error transcribing audio');
    }
  });
});

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
