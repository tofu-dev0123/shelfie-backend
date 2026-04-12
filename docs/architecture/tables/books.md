# books

## 概要

楽天書籍APIから取得した書籍データのキャッシュテーブル。
ユーザーが初めてある書籍を本棚に追加した際に作成され、以降は DB のデータを使用します。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| isbn | string(13) | NO | UNIQUE | ISBNコード（書籍の一意識別子）|
| title | string(255) | NO | | 書籍タイトル |
| authors | string(255)[] | NO | | 著者名の配列 |
| thumbnail_url | string(2048) | YES | | 書影画像 URL |
| published_date | string(10) | YES | | 出版日（YYYY or YYYY-MM-DD）|
| created_at | datetime | NO | | |
| updated_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | isbn | 同一書籍の重複登録防止・ISBN での検索 |

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| user_books | 1:N | この書籍の本棚投稿 |

## 備考

- `authors` は PostgreSQL の配列型（`varchar(255)[]`）で保存します。楽天書籍APIのレスポンスは著者名を「／」区切りの文字列で返すため、分割して配列として保存します。Rails migration では `array: true` を指定し、要素の型は `varchar(255)` とします（著者名1件あたり最大255文字）
- 著者の重複管理は行いません。著者単位でのブラウズ機能がなく、書籍検索は楽天書籍APIが担うため、正規化するメリットが薄いと判断しました
- `description`（書籍説明文）は DB に保存しません。書籍詳細ページのメインコンテンツはユーザーが書いた投稿内容であるため不要と判断しました
- `published_date` は年のみの場合（`"2019"` など）があるため string 型で保持します
- 書籍データの更新は行わず、初回登録時のスナップショットを保持します
