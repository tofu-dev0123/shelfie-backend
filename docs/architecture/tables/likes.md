# likes

## 概要

本棚投稿へのいいねを管理するテーブル。
リアクション機能としての「いいね数の表示」と、ブックマーク機能としての「いいねした投稿の一覧表示」の両方を担います。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| user_id | bigint | NO | FK → users | いいねしたユーザー |
| user_book_id | bigint | NO | FK → user_books | いいねされた投稿 |
| created_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | (user_id, user_book_id) | 同じ投稿への重複いいね防止 |
| INDEX | user_id | 自分がいいねした投稿一覧取得 |
| INDEX | user_book_id | 投稿のいいね数・いいねユーザー取得 |

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| users | N:1 | いいねしたユーザー |
| user_books | N:1 | いいねされた投稿 |

## 備考

- いいね数は `likes` テーブルの COUNT で取得します
- 自分がいいねした投稿一覧（ブックマーク一覧）はいいねした順（created_at DESC）で表示します
