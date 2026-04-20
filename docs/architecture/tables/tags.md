# tags

## 概要

技術タグのマスタテーブル。本棚投稿の `content` に含まれるハッシュタグから動的に生成される（`Tag.find_or_create_safely!`）。
`user_book_tags` を通じて本棚投稿に紐付けられ、スキルマップやサジェスト（`GET /v1/tags`）に使用される。

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

## 備考

- タグは本棚投稿の `content` 中のハッシュタグから自動生成される。ハッシュタグ抽出仕様は `docs/api/user_books/create.md` を参照
- 同名タグの同時作成は `Tag.find_or_create_safely!` が `RecordNotUnique` を検知して既存レコードに合流させる
- タグ削除時は `user_book_tags` を先に削除する必要がある（ON DELETE RESTRICT）
