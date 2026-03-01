# users

## 概要

ユーザー情報を管理するテーブル。Google OAuth によるログイン情報と、プロフィール情報を保持します。
Google アカウントから取得・保存するのは `google_uid` と `email` のみです。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| google_uid | string | NO | UNIQUE | Google OAuth の識別子 |
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
| UNIQUE | google_uid | OAuth ログイン時のユーザー特定 |
| UNIQUE | email | メールアドレスの一意性保証 |
| UNIQUE | username | ユーザー名の一意性保証 |
| INDEX | username | ユーザー検索 |

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| user_links | 1:N | プロフィールリンク（最大5件）|
| user_books | 1:N | 本棚投稿 |
| follows (follower_id) | 1:N | フォローしているユーザー |
| follows (followee_id) | 1:N | フォロワー |
| likes | 1:N | いいねした投稿 |

## 備考

- 初回ログイン時は Google の表示名を `nickname` の入力欄にプリフィルして表示しますが、DB には保存しません
- `avatar_url` が NULL の場合、アプリケーション側でデフォルト画像を表示します
- ユーザーが独自のアイコン画像をアップロードする場合は画像ストレージ（Active Storage + S3 等）が必要です
