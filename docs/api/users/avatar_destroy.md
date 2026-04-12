# DELETE /v1/me/avatar

## 概要

アバター画像を削除する。冪等性あり（アバターが存在しない場合も 200 を返す）。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. S3 からファイルを削除（aws-sdk-s3 を直接使用）
3. Users テーブルの `avatar_key` を NULL に更新

## レスポンス

### 成功

```json
// 200 OK
{
  "message": "削除が完了しました"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `INTERNAL_SERVER_ERROR` | 500 | S3 削除失敗 |
