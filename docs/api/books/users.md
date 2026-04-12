# GET /v1/books/:isbn/users

## 概要

指定した書籍を本棚に登録しているユーザー一覧を取得する。

## リクエスト

### 認証

不要

### パスパラメータ

| パラメータ | 型 | 説明 |
|---|---|---|
| `:isbn` | string | ISBNコード |

### クエリパラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|---|---|---|---|---|
| `cursor` | string | 任意 | なし | 前回レスポンスの `next_cursor` |
| `limit` | integer | 任意 | 20 | 最大取得件数。上限は50で、超えた場合は50にクランプされる |

## 処理詳細

1. `isbn` で Books テーブルを検索
2. `books.isbn` → `books.id` → `user_books.user_id` → `users.*` の順でJOINし、1クエリでユーザー一覧を取得
3. カーソルベースでページネーションして返す

```sql
SELECT users.*
FROM users
INNER JOIN user_books ON users.id = user_books.user_id
INNER JOIN books ON books.id = user_books.book_id
WHERE books.isbn = :isbn
ORDER BY user_books.id
LIMIT 20;
```

## レスポンス

### 成功

書籍が Books テーブルに存在しない場合、またはユーザーが0件の場合も `items: []` で200を返す。

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
