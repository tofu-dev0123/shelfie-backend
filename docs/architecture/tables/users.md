# users

## 概要

ユーザーのプロフィール情報を管理するテーブル。
**外部プロバイダとの連携情報は持たない。** それは
[user_identities](./user_identities.md) が担う。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| email | string(254) | NO | UNIQUE | **アカウントの連絡先メール**（サインアップ時に最初のプロバイダから設定）|
| nickname | string(50) | NO | | アプリ上の表示名（サインアップ時に設定必須）|
| username | string(40) | NO | UNIQUE | @ ハンドル（サインアップ時に設定必須）|
| bio | text | YES | | 自己紹介文 |
| created_at | datetime | NO | | |
| updated_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | email | 連絡先メールの一意性保証。同一メールで別プロバイダが来たときの拒否判定（P1）にも使う |
| UNIQUE | username | ユーザー名の一意性保証（PostgreSQL では UNIQUE 制約により検索用インデックスが自動生成されるため、別途 INDEX は不要）|

**ログイン時のユーザー特定にこのテーブルは使わない。**
`user_identities` の `(provider, provider_uid)` から辿る。

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| user_identities | 1:N | 外部プロバイダとの連携（v1 では1件）|
| user_links | 1:N | プロフィールリンク（最大5件）|
| user_books | 1:N | 本棚投稿 |
| refresh_tokens | 1:N | リフレッシュトークン |

## email の役割の違い

| | 意味 |
|---|---|
| `users.email` | **アカウントの連絡先メール。** UNIQUE を維持する |
| `user_identities.email` | **そのプロバイダが返したメール。** `users.email` と一致しなくてよい |

**両者は一致しなくてよい。** Google と GitHub で別のメールを使っているユーザーがいるため、
プロバイダが返したメールをアカウントの連絡先と同一視できない。

サインアップ時は最初のプロバイダのメールを両方に入れるが、以降は独立して扱う。

## 備考

- サインアップ時は `signup_token` の `name` クレーム（IdP の表示名）を `nickname` の
  入力欄にプリフィルして表示するが、**DB には保存しない**
- `bio` の最大文字数（500文字）はアプリケーション層のバリデーションで制御する

## 関連ドキュメント

- [user_identities テーブル定義](./user_identities.md)
- [認証フロー](../auth.md)
- [サインアップフロー](../signup.md)
