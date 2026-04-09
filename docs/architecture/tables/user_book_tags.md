# user_book_tags

## 概要

本棚投稿（`user_books`）とタグ（`tags`）の中間テーブル。
ユーザーが本棚投稿に技術タグを付与する際に使用される。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| user_book_id | bigint | NO | FK → user_books | |
| tag_id | bigint | NO | FK → tags | |
| created_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | (user_book_id, tag_id) | 同一投稿への重複タグ付与防止 |
| INDEX | tag_id | タグ別フィード取得クエリの効率化 |

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| user_books | N:1 | タグが付いた本棚投稿 |
| tags | N:1 | 付与されたタグ |

## 備考

- 1投稿（`user_book_id`）につき最大5件のタグ付与制限はアプリケーション層のバリデーションで制御します
