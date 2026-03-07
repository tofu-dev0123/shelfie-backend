# user_books

## 概要

ユーザーの本棚投稿を管理するテーブル。
読了した書籍の要約・感想を投稿する単位であり、Shelfie のコアエンティティです。
1ユーザーにつき同じ書籍は1件のみ登録可能。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| user_id | bigint | NO | FK → users | |
| book_id | bigint | NO | FK → books | |
| content | text | YES | | 投稿本文（要約・感想など用途は自由）最大1000文字 |
| created_at | datetime | NO | | |
| updated_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | (user_id, book_id) | 同じ本の重複投稿防止 |
| INDEX | (user_id, created_at DESC) | フィード取得クエリ（IN + ORDER BY created_at DESC）の効率化 |
| INDEX | book_id | 書籍を登録しているユーザー一覧取得 |

## 備考

- `content` は NULL 許容のため、本文なしで書籍のみ登録することも可能です
- 文字数制限（最大1000文字）はアプリケーション層のバリデーションで制御します

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| users | N:1 | 投稿したユーザー |
| books | N:1 | 対象書籍 |
| user_book_purchase_links | 1:N | 購入リンク |
| likes | 1:N | いいね |
