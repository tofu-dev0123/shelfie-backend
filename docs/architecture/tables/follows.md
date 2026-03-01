# follows

## 概要

ユーザー間のフォロー関係を管理するテーブル。
フォローベースのフィード機能の基盤となります。

## カラム定義

| カラム名 | 型 | NULL | 制約 | 説明 |
|---|---|---|---|---|
| id | bigint | NO | PK | |
| follower_id | bigint | NO | FK → users | フォローしているユーザー |
| followee_id | bigint | NO | FK → users | フォローされているユーザー |
| created_at | datetime | NO | | |

## インデックス

| インデックス | カラム | 用途 |
|---|---|---|
| PRIMARY KEY | id | |
| UNIQUE | (follower_id, followee_id) | 重複フォロー防止 |
| INDEX | follower_id | 自分がフォローしているユーザー一覧取得 |
| INDEX | followee_id | 自分のフォロワー一覧取得 |

## リレーション

| 関連テーブル | 種別 | 説明 |
|---|---|---|
| users (follower_id) | N:1 | フォローしているユーザー |
| users (followee_id) | N:1 | フォローされているユーザー |

## 備考

- 自分自身へのフォローはアプリケーション層のバリデーションで防止します
- フィードの取得クエリ例:

```sql
SELECT user_books.*
FROM user_books
WHERE user_books.user_id IN (
  SELECT followee_id FROM follows WHERE follower_id = :current_user_id
)
ORDER BY user_books.created_at DESC;
```
