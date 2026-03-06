# エンドポイント一覧

## 認証

| メソッド | パス | 説明 | 認証 |
|---|---|---|---|
| POST | `/v1/auth/login` | Clerk JWT → 独自JWT発行 | Clerk JWT |
| POST | `/v1/auth/refresh` | アクセストークン再発行 | Cookie |
| DELETE | `/v1/auth/logout` | ログアウト | アクセストークン |

## ユーザー

| メソッド | パス | 説明 | 認証 |
|---|---|---|---|
| POST | `/v1/users` | ユーザー作成 | Clerk JWT |
| GET | `/v1/users/username/check?value=` | username重複チェック | 不要 |
| GET | `/v1/users/:username` | ユーザープロフィール取得 | 不要 |
| GET | `/v1/me` | 自分のプロフィール取得 | 必須 |
| PATCH | `/v1/me` | 自分のプロフィール更新 | 必須 |
| PUT | `/v1/me/links` | プロフィールリンク一括更新 | 必須 |

## 書籍

| メソッド | パス | 説明 | 認証 |
|---|---|---|---|
| GET | `/v1/books/search?q=` | 書籍検索 | 必須 |
| GET | `/v1/books/:google_books_id` | 書籍詳細 | 不要 |
| GET | `/v1/books/:google_books_id/users` | その書籍を読んだユーザー一覧 | 不要 |

## 本棚投稿

| メソッド | パス | 説明 | 認証 |
|---|---|---|---|
| GET | `/v1/users/:username/books` | ユーザーの本棚一覧 | 不要 |
| GET | `/v1/users/:username/books/:google_books_id` | 投稿詳細 | 不要 |
| POST | `/v1/me/books` | 本棚に追加 | 必須 |
| PATCH | `/v1/me/books/:google_books_id` | 投稿内容更新 | 必須 |
| DELETE | `/v1/me/books/:google_books_id` | 投稿削除 | 必須 |

## フォロー

| メソッド | パス | 説明 | 認証 |
|---|---|---|---|
| POST | `/v1/me/follows/:username` | フォロー | 必須 |
| DELETE | `/v1/me/follows/:username` | フォロー解除 | 必須 |
| GET | `/v1/users/:username/followers` | フォロワー一覧 | 不要 |
| GET | `/v1/users/:username/following` | フォロー中一覧 | 不要 |

## いいね

| メソッド | パス | 説明 | 認証 |
|---|---|---|---|
| POST | `/v1/me/likes/:username/:google_books_id` | いいね | 必須 |
| DELETE | `/v1/me/likes/:username/:google_books_id` | いいね取り消し | 必須 |

## フィード

| メソッド | パス | 説明 | 認証 |
|---|---|---|---|
| GET | `/v1/feed` | フィード（ログイン時はフォロー中、未ログイン時は全体） | 任意 |
