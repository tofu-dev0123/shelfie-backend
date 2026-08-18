# エンドポイント一覧

## Swagger命名規則

- **グループ名（tags）**: `〜系`
- **オペレーション名（summary）**: `〜API`

## `/v1` 外エンドポイント

OAuth の認可リクエストとコールバックは `/v1` の外に置く。

理由は3つある。①JSON API ではなくブラウザのトップレベル遷移で叩かれる ②レスポンスが常に 302 リダイレクトで、エラーも JSON ではなくリダイレクトで返す ③IdP に登録する `redirect_uri` は API のバージョンとは独立して安定していてほしい。

そのため `V1::BaseController` を継承せず、`ErrorHandler` も通さない。Swagger にも載せない（リダイレクト系はスキーマで表現する価値が薄い）。

| メソッド | パス | 説明 | 認証 | 仕様書 |
|---|---|---|---|---|
| GET | `/auth/:provider` | 認可リクエスト開始 | 不要 | [oauth/start.md](./oauth/start.md) |
| GET | `/auth/:provider/callback` | 認可レスポンス受け取り | `oauth_state` Cookie | [oauth/callback.md](./oauth/callback.md) |

`:provider` は `google` / `github` のみ。それ以外はルーティング制約で 404。

## 認証系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/auth/signup_context` | サインアップコンテキスト取得API | サインアップ画面の初期表示情報 | `signup_token` Cookie |
| POST | `/v1/auth/refresh` | アクセストークン再発行API | アクセストークン再発行 | Cookie |
| DELETE | `/v1/auth/logout` | ログアウトAPI | ログアウト | アクセストークン |

## ユーザー系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| POST | `/v1/users` | ユーザー登録API | ユーザー作成 | `signup_token` Cookie |
| GET | `/v1/users/username/check?value=` | ユーザーネーム重複チェックAPI | username重複チェック | 不要 |
| GET | `/v1/users/:username` | ユーザープロフィール取得API | ユーザープロフィール取得 | 不要 |

> **実装上の注意:** `/v1/users/username/check` の `username` はリテラルであり、`:username` パラメータではありません。実装時は `:username` ルートより前に定義してください。

## マイページ系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/me` | マイプロフィール取得API | 自分のプロフィール取得 | 必須 |
| PATCH | `/v1/me` | プロフィール更新API | 自分のプロフィール更新（テキスト情報・リンク） | 必須 |

## 書籍系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/books/search?q=` | 書籍検索API | 書籍検索 | 必須 |
| GET | `/v1/books/:isbn` | 書籍詳細取得API | ISBN指定で書籍を取得 | 必須 |
| GET | `/v1/books/:isbn/users` | 既読書籍ユーザー一覧取得API | その書籍を読んだユーザー一覧 | 不要 |

## 本棚系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/users/:username/books` | 本棚一覧取得API | ユーザーの本棚一覧 | 不要 |
| GET | `/v1/users/:username/books/:isbn` | 本棚投稿詳細取得API | 投稿詳細 | 不要 |
| POST | `/v1/me/books` | 本棚追加API | 本棚に追加 | 必須 |
| PUT | `/v1/me/books/:isbn` | 本棚投稿更新API | 投稿内容更新 | 必須 |
| DELETE | `/v1/me/books/:isbn` | 本棚投稿削除API | 投稿削除 | 必須 |
