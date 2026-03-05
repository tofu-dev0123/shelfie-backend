# GET /v1/users/username/check

## 概要

username の重複チェックを行う。サインアップ時にデバウンスで呼び出される。

## リクエスト

### 認証

不要

### クエリパラメータ

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `value` | string | 必須 | チェックする username |

## 処理詳細

1. `value` のバリデーション（形式チェック）
2. `users` テーブルで `username` の存在チェック
3. 結果を返す

## レスポンス

### 成功

```json
// 200 OK
{
  "available": true
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `VALIDATION_ERROR` | 422 | `value` が空・形式不正 |
