# GET /v1/users/:username

## 概要

指定したユーザーのプロフィール情報を取得する。

## リクエスト

### 認証

任意（トークンがある場合は `is_following` を返す）

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:username` | string | 取得するユーザーの username |

## 処理詳細

1. `username` で User レコードを検索
2. プロフィール情報・リンク一覧・フォロワー数・フォロー数・読了数を返す
   - 各カウントは集計クエリで毎回計算する
   - `books_count` は本棚に登録済みの書籍数をカウントする
3. 認証済みの場合、リクエストユーザーが対象ユーザーをフォローしているか返す
   - 自分自身のプロフィールを取得した場合は `false` を返す

## レスポンス

### 成功

```json
// 200 OK（未認証時）
{
  "username": "komusan",
  "nickname": "コムさん",
  "bio": "エンジニアです",
  "followers_count": 10,
  "following_count": 5,
  "books_count": 20,
  "links": [
    "https://github.com/komusan"
  ]
}
```

```json
// 200 OK（認証済み時）
{
  "username": "komusan",
  "nickname": "コムさん",
  "bio": "エンジニアです",
  "followers_count": 10,
  "following_count": 5,
  "books_count": 20,
  "links": [
    "https://github.com/komusan"
  ],
  "is_following": true
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `NOT_FOUND` | 404 | ユーザーが存在しない |
