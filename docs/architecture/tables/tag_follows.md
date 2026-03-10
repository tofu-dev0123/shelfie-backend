# tag_follows

## 概要

ユーザーとタグのフォロー関係を管理するテーブル。
ユーザーがタグをフォローすると、そのタグが付いた本棚投稿がフィードに表示される。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| user_id | bigint | NO | FK → users | フォローしているユーザー |
| tag_id | bigint | NO | FK → tags | フォローされているタグ |
| created_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | (user_id, tag_id) | 重複フォロー防止 |
| INDEX | user_id | ユーザーがフォローしているタグ一覧取得 |

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| users | N:1 | フォローしているユーザー |
| tags | N:1 | フォローされているタグ |

## 備考

- タグフォローに基づくフィードクエリでは `user_book_tags` と結合して投稿を取得する
- フィードには `status = 'reading'` または `status = 'completed'` の投稿のみ表示する（`want_to_read` は除外）
