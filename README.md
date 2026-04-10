# surgery_memo
todo AI 要約
todo 課金されたら課金ページの購入ボタン非表示、登録済み表示

AppCheckエラー
"error": {
    "code": 400,
    "message": "API key not valid. Please pass a valid API key.",
    "status": "INVALID_ARGUMENT",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "API_KEY_INVALID",
        "domain": "googleapis.com",
        "metadata": {
          "service": "firebaseappcheck.googleapis.com"
        }
      },
      {
        "@type": "type.googleapis.com/google.rpc.LocalizedMessage",
        "locale": "en-US",
        "message": "API key not valid. Please pass a valid API key."
      }
    ]
  }
  が出たらここで設定
  https://console.firebase.google.com/u/0/project/surgery-counselling-memo/appcheck/apps?hl=ja