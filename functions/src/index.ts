import * as functions from 'firebase-functions';
import * as speech from '@google-cloud/speech';
import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import multer from 'multer';
import * as path from 'path';

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
