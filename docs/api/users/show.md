# GET /v1/users/:username

## 概要

指定したユーザーのプロフィール情報を取得する。

## リクエスト

### 認証

不要

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:username` | string | 取得するユーザーの username |

## 処理詳細

1. `username` で User レコードを検索
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
| `NOT_FOUND` | 404 | ユーザーが存在しない |
