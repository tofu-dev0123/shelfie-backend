# GET /v1/users/:username/followers

## 概要

指定したユーザーのフォロワー一覧を取得する。

## リクエスト

### 認証

不要

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:username` | string | 取得するユーザーの username |

### クエリパラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `cursor` | string | 任意 | なし | 前回レスポンスの `next_cursor` |
| `limit` | integer | 任意 | 20 | 最大取得件数（上限50） |

## 処理詳細

1. `username` で User レコードを検索
2. `follows` テーブルから `followee_id` が一致するレコードを取得し、フォロワーのユーザー情報を返す

## レスポンス

### 成功

```json
// 200 OK
{
  "items": [
    {
      "username": "komusan",
      "nickname": "コムさん",
      "avatar_url": null
    }
  ],
  "pagination": {
    "next_cursor": "eyJpZCI6NDJ9",
    "has_next": true
  }
}
```

### エラー

| code | ステータス | 場面 |
|---|---|---|
| `NOT_FOUND` | 404 | ユーザーが存在しない |
