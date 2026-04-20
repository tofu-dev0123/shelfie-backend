# GET /v1/users/:username/following

## 概要

指定したユーザーのフォロー中一覧を取得する。

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
| `limit` | integer | 任意 | 20 | 最大取得件数。上限は50で、超えた場合は50にクランプされる |

## 処理詳細

1. `username` で User レコードを検索
2. `follows` テーブルから `follower_id` が一致するレコードを取得し、`follows.id` の降順（新しくフォローした順）でフォロー中のユーザー情報を返す
3. カーソルベースでページネーションして返す

## レスポンス

### 成功

ユーザーが存在しない場合、またはフォロー中ユーザーが0件の場合も `items: []` で 200 を返す。

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
