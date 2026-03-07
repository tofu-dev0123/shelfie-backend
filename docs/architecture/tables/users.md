# users

## 概要

ユーザー情報を管理するテーブル。Clerk による認証情報と、プロフィール情報を保持します。
Clerk から取得・保存するのは `clerk_user_id` と `email` のみです。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| clerk_user_id | string | NO | UNIQUE | Clerk のユーザー ID（JWT の `sub` クレーム） |
| email | string | NO | UNIQUE | Google アカウントのメールアドレス |
| nickname | string | NO | | アプリ上の表示名（初回ログイン時に設定必須）|
| username | string | NO | UNIQUE | @ ハンドル（初回ログイン時に設定必須）|
| avatar_url | string | YES | | プロフィールアイコン画像 URL（NULL の場合はデフォルト画像を表示）|
| bio | text | YES | | 自己紹介文 |
| created_at | datetime | NO | | |
| updated_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | clerk_user_id | ログイン時のユーザー特定 |
| UNIQUE | email | メールアドレスの一意性保証 |
| UNIQUE | username | ユーザー名の一意性保証（PostgreSQL では UNIQUE 制約により検索用インデックスが自動生成されるため、別途 INDEX は不要）|

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| user_links | 1:N | プロフィールリンク（最大5件）|
| user_books | 1:N | 本棚投稿 |
| follows (follower_id) | 1:N | フォローしているユーザー |
| follows (followee_id) | 1:N | フォロワー |
| likes | 1:N | いいねした投稿 |

## 備考

- 初回ログイン時は Clerk JWT の `name` クレーム（Google アカウントの表示名）を `nickname` の入力欄にプリフィルして表示しますが、DB には保存しません
- `avatar_url` が NULL の場合、アプリケーション側でデフォルト画像を表示します
- ユーザーが独自のアイコン画像をアップロードする場合は画像ストレージ（Active Storage + S3 等）が必要です
