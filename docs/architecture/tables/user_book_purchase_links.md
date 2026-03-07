# user_book_purchase_links

## 概要

本棚投稿に紐づく購入リンクを管理するテーブル。
現在は1投稿につき1件の運用を想定していますが、将来的な複数リンク対応を見据えて user_books とは別テーブルに切り出しています。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| user_book_id | bigint | NO | FK → user_books | |
| url | string | NO | | 購入 URL |
| created_at | datetime | NO | | |
| updated_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| INDEX | user_book_id | 投稿に紐づく購入リンク取得 |

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| user_books | N:1 | 紐づく本棚投稿 |

## 備考

- 現在は1件運用ですが、複数件対応への移行はアプリケーション層の変更のみで対応可能です
- 複数リンク対応時に同一 URL の重複を許可しない場合は `UNIQUE (user_book_id, url)` を検討する
- アイコン表示の判定はフロントエンド側で URL パターンマッチングにより行います（user_links と同様の設計）
