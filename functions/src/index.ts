/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {GoogleAuth} from "google-auth-library";

const auth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});

async function getAccessToken(): Promise<string> {
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  if (!tokenResponse.token) {
    throw new Error("Failed to obtain access token.");
  }
  return tokenResponse.token;
}

export const summarizeTranscript = onRequest(async (request, response) => {
  if (request.method !== "POST") {
    response.status(405).send("Method not allowed");
    return;
  }

  const transcript = typeof request.body?.transcript === "string"
    ? request.body.transcript.trim()
    : "";
  const language = request.body?.language === "韓国語" ? "韓国語" : "日本語";

  if (!transcript) {
    response.status(400).json({ error: "Transcript is required." });
    return;
  }


  const prompt = `以下の相談内容を${language}で、主要なポイントを4つ程度の箇条書きで要約してください。\n\n文字起こし:\n${transcript}\n\n要約:`;

  try {
    const accessToken = await getAccessToken();
    const modelUrl = "https://generativelanguage.googleapis.com/v1beta2/models/gemini-1.5:generateText";
    const result = await fetch(modelUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        prompt: {
          text: prompt,
        },
      }),
    });

    if (!result.ok) {
      const errorBody = await result.text();
      logger.error("Gemini request failed", { status: result.status, body: errorBody });
      response.status(500).json({ error: "Gemini summarization failed." });
      return;
    }

    const json = await result.json();
    const summary = String(json?.candidates?.[0]?.output ?? "").trim();
    response.status(200).json({ summary });
  } catch (error) {
    logger.error("Gemini summarization failed", { error });
    response.status(500).json({ error: "Failed to generate summary." });
  }
});
