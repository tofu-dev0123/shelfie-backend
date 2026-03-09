# user_book_purchase_links

## 概要

本棚投稿に紐づく購入リンクを管理するテーブル。
1投稿につき最大3件まで登録できます。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| user_book_id | bigint | NO | FK → user_books | |
| url | string(2048) | NO | | 購入 URL |
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

- 1投稿あたり最大3件まで登録可能
- 同一 URL の重複を許可しない場合は `UNIQUE (user_book_id, url)` を検討する
- アイコン表示の判定はフロントエンド側で URL パターンマッチングにより行います（user_links と同様の設計）
