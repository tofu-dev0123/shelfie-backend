# books

## 概要

Google Books API から取得した書籍データのキャッシュテーブル。
ユーザーが初めてある書籍を本棚に追加した際に作成され、以降は DB のデータを使用します。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| google_books_id | string(50) | NO | UNIQUE | Google Books API の書籍 ID |
| title | string(255) | NO | | 書籍タイトル |
| authors | string[] | NO | | 著者名の配列（Google Books API のレスポンスをそのまま保存）|
| isbn | string(17) | YES | | ISBN-13（存在しない場合は NULL）|
| thumbnail_url | string(2048) | YES | | 書影画像 URL |
| published_date | string(10) | YES | | 出版日（Google Books の形式に準拠: YYYY or YYYY-MM-DD）|
| created_at | datetime | NO | | |
| updated_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | google_books_id | 同一書籍の重複登録防止・API ID での検索 |

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| user_books | 1:N | この書籍の本棚投稿 |

## 備考

- `authors` は PostgreSQL の配列型で保存します。Google Books API のレスポンスが配列形式のためそのまま保存でき、Rails・フロントエンドともに配列として扱えます
- 著者の重複管理は行いません。著者単位でのブラウズ機能がなく、書籍検索は Google Books API が担うため、正規化するメリットが薄いと判断しました
- `description`（書籍説明文）は DB に保存しません。書籍詳細ページのメインコンテンツはユーザーが書いた `summary` / `review` であるため不要と判断しました
- `published_date` は Google Books API の仕様上、`"2019"` のように年のみの場合があるため string 型で保持します
- 書籍データの更新は行わず、初回登録時のスナップショットを保持します
