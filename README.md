# surgery_memo

AI要約はアプリから直接 Gemini を呼ばず、Cloud Run 関数 `summarizeCounseling` 経由で実行する。

関数側の Gemini API キーは Firebase Functions の Secret として設定する。

```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions:summarizeCounseling
```
