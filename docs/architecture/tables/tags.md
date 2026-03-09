# tags

## 概要

技術タグのマスタテーブル。管理側でシードデータとして一括管理し、ユーザーは既存タグから選択する。
`user_book_tags` を通じて本棚投稿に紐付けられ、スキルマップやフィードのフィルタリングに使用される。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| name | string(50) | NO | UNIQUE | タグ名（例: `Go`, `TypeScript`, `AWS`）|
| created_at | datetime | NO | | |
| updated_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | name | タグ名の一意性保証・名前検索 |

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| user_book_tags | 1:N | このタグが付いた本棚投稿 |
| tag_follows | 1:N | このタグをフォローしているユーザー |

## 備考

- タグの追加・削除は管理側のみが行う。ユーザーによる自由なタグ作成は不可
- タグ削除時は `user_book_tags`・`tag_follows` を先に削除する必要がある（ON DELETE RESTRICT）
