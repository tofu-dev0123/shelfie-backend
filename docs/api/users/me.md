# GET /v1/me

## 概要

ログイン中のユーザー自身のプロフィール情報を取得する。

## リクエスト

### 認証

`Authorization: Bearer <アクセストークン>`

## 処理詳細

1. アクセストークンを検証してログインユーザーを特定
2. プロフィール情報・リンク一覧・フォロワー数・フォロー数・投稿数を返す
   - 各カウントは集計クエリで毎回計算する

## レスポンス

### 成功

```json
// 200 OK
{
  "id": 1,
  "username": "komusan",
  "nickname": "コムさん",
  "bio": "エンジニアです",
  "avatar_url": null,
  "followers_count": 10,
  "following_count": 5,
  "books_count": 20,
  "links": [
    "https://github.com/komusan"
  ]
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `UNAUTHORIZED` | 401 | アクセストークンが無効・期限切れ |
