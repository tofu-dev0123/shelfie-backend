# エンドポイント一覧

## Swagger命名規則

- **グループ名（tags）**: `〜系`
- **オペレーション名（summary）**: `〜API`

## 認証系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| POST | `/v1/auth/login` | ログインAPI | Clerk JWT → 独自JWT発行 | Clerk JWT |
| POST | `/v1/auth/refresh` | アクセストークン再発行API | アクセストークン再発行 | Cookie |
| DELETE | `/v1/auth/logout` | ログアウトAPI | ログアウト | アクセストークン |

## ユーザー系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| POST | `/v1/users` | ユーザー登録API | ユーザー作成 | Clerk JWT |
| GET | `/v1/users/username/check?value=` | ユーザーネーム重複チェックAPI | username重複チェック | 不要 |
| GET | `/v1/users/:username` | ユーザープロフィール取得API | ユーザープロフィール取得 | 不要 |
| GET | `/v1/users/:username/skill_map` | タグ別読了数取得API | タグ別読了数 | 不要 |

> **実装上の注意:** `/v1/users/username/check` の `username` はリテラルであり、`:username` パラメータではありません。実装時は `:username` ルートより前に定義してください。

## マイページ系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/me` | マイプロフィール取得API | 自分のプロフィール取得 | 必須 |
| PATCH | `/v1/me` | プロフィール更新API | 自分のプロフィール更新（テキスト情報・リンク） | 必須 |
| POST | `/v1/me/avatar` | アバター画像アップロードAPI | アバター画像アップロード | 必須 |
| DELETE | `/v1/me/avatar` | アバター画像削除API | アバター画像削除 | 必須 |

## 書籍系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/books/search?q=` | 書籍検索API | 書籍検索 | 必須 |
| GET | `/v1/books/:isbn/users` | 既読書籍ユーザー一覧取得API | その書籍を読んだユーザー一覧 | 不要 |

## 本棚系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/users/:username/books` | 本棚一覧取得API | ユーザーの本棚一覧 | 不要 |
| GET | `/v1/users/:username/books/:isbn` | 本棚投稿詳細取得API | 投稿詳細 | 不要 |
| POST | `/v1/me/books` | 本棚追加API | 本棚に追加 | 必須 |
| PUT | `/v1/me/books/:isbn` | 本棚投稿更新API | 投稿内容更新 | 必須 |
| DELETE | `/v1/me/books/:isbn` | 本棚投稿削除API | 投稿削除 | 必須 |

## フォロー系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| POST | `/v1/me/follows/:username` | フォローAPI | フォロー | 必須 |
| DELETE | `/v1/me/follows/:username` | フォロー解除API | フォロー解除 | 必須 |
| GET | `/v1/users/:username/followers` | フォロワー一覧取得API | フォロワー一覧 | 不要 |
| GET | `/v1/users/:username/following` | フォロー中一覧取得API | フォロー中一覧 | 不要 |

## 読みたい系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/me/want_to_reads` | 読みたいリスト取得API | 自分の読みたいリスト取得 | 必須 |
| POST | `/v1/me/want_to_reads/:isbn` | 読みたい追加API | 読みたいリストに追加 | 必須 |
| DELETE | `/v1/me/want_to_reads/:isbn` | 読みたい削除API | 読みたいリストから削除 | 必須 |

## タグ系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/tags?q=` | タグサジェストAPI | タグサジェスト（オートコンプリート用、前方一致優先・部分一致） | 不要 |
| GET | `/v1/me/tag_follows` | フォロー中タグ一覧取得API | フォロー中タグ一覧 | 必須 |
| POST | `/v1/me/tag_follows/:tag_name` | タグフォローAPI | タグをフォロー | 必須 |
| DELETE | `/v1/me/tag_follows/:tag_name` | タグフォロー解除API | タグのフォロー解除 | 必須 |

## フィード系

| メソッド | パス | オペレーション名 | 説明 | 認証 |
|---|---|---|---|---|
| GET | `/v1/feed` | フィード取得API | フィード（ユーザーフォローベース） | 任意（未認証は全員投稿） |
| GET | `/v1/feed/tags` | タグフィード取得API | フィード（タグフォローベース） | 必須 |
