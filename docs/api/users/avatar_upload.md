# POST /v1/me/avatar

## 概要

アバター画像をアップロードする。既存の画像がある場合は上書きする。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

### ボディ

```
Content-Type: multipart/form-data

avatar: <バイナリファイル>
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `avatar` | file | 必須 | アップロードする画像ファイル |

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. ファイルを S3 にアップロード（aws-sdk-s3 を直接使用）
3. 既存の画像がある場合は S3 の既存ファイルを上書き
4. `avatar_key`（S3 のキーパス）を Users テーブルに保存
5. CloudFront の URL を組み立てて返す

## レスポンス

### 成功

```json
// 200 OK
{
  "avatar_url": "https://d1234abcd.cloudfront.net/profile-images/user_123.jpg"
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
| `UNPROCESSABLE_ENTITY` | 422 | ファイルが不正（形式・サイズなど） |
