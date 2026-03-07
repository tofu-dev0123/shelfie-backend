# refresh_tokens テーブル

## 概要

リフレッシュトークンを管理するテーブルです。
ログインのたびにレコードが1件作成され、デバイスごとの個別ログアウトと強制ログアウトを実現します。

## カラム定義

| カラム | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| `id` | bigint | NO | PK | |
| `user_id` | bigint | NO | FK (users.id) | トークンの所有者 |
| `token` | string(128) | NO | UNIQUE | トークンの値 |
| `expires_at` | datetime | NO | | 有効期限 |
| `created_at` | datetime | NO | | 発行日時 |

## インデックス

| カラム | 種別 | 理由 |
|---|---|---|
| `token` | UNIQUE | トークンの一意性保証・高速検索 |
| `user_id` | INDEX | ユーザーの全トークン取得（全デバイスログアウト）|
| `expires_at` | INDEX | 期限切れトークンの定期削除バッチ向け |

## 備考

- レコードは作成・削除のみ行い、更新は行わないため `updated_at` は持たない

## 関連ドキュメント

- [認証フロー](../auth.md)
