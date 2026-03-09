# データモデル

## ER図

```
┌──────────────┐       ┌──────────────────┐       ┌──────────────────────────┐
│  user_links  │       │    user_books    │  1:N  │ user_book_purchase_links │
├──────────────┤       ├──────────────────┤       ├──────────────────────────┤
│ id           │       │ id               │───────│ id                       │
│ user_id      │  N:1  │ user_id          │       │ user_book_id             │
│ url          │       │ book_id          │       │ url                      │
└──────┬───────┘       │ status           │       └──────────────────────────┘
       │               │ content          │
       │               └──┬─────┬──────┬──┘
       │ N:1              │ N:1 │ 1:N  │ 1:N
┌──────▼───────┐          │  ┌──▼────┐ └───────────────┐
│    users     │──────────┘  │ likes │  user_book_tags │
├──────────────┤             ├───────┤ ├────────────────┤
│ id           │  1:N        │ id    │ │ id             │
│ clerk_user_id│◄────────────│user_id│ │ user_book_id   │  N:1  ┌──────┐
│ email        │             │user_  │ │ tag_id         │───────│ tags │
│ nickname     │             │book_id│ └────────────────┘       ├──────┤
│ username     │             └───────┘                          │ id   │
│ avatar_url   │                                                 │ name │
│ bio          │  follows          tag_follows                   └──────┘
└──────┬───────┘  ┌──────────────┐ ┌─────────────┐
       │          │ follower_id  │ │ user_id     │──► users
       │          │ followee_id  │ │ tag_id      │──► tags
       │          └──────────────┘ └─────────────┘
       │          （→ users）
       └── 1:N ──►┌──────────────┐
                  │    books     │
                  ├──────────────┤
                  │ id           │
                  │ google_      │
                  │ books_id     │
                  │ title        │
                  │ authors[]    │
                  └──────────────┘
```

---

## テーブル一覧

| テーブル | 用途 |
|---|---|
| [users](./tables/users.md) | ユーザー情報 |
| [user_links](./tables/user_links.md) | プロフィールリンク（最大5件）|
| [books](./tables/books.md) | 書籍データ（Google Books API キャッシュ）|
| [user_books](./tables/user_books.md) | 本棚投稿 |
| [user_book_purchase_links](./tables/user_book_purchase_links.md) | 購入リンク |
| [tags](./tables/tags.md) | 技術タグマスタ |
| [user_book_tags](./tables/user_book_tags.md) | 本棚投稿へのタグ付け |
| [tag_follows](./tables/tag_follows.md) | タグフォロー |
| [follows](./tables/follows.md) | フォロー関係 |
| [likes](./tables/likes.md) | いいね |
| [refresh_tokens](./tables/refresh_tokens.md) | リフレッシュトークン管理 |

---

## 主なユニーク制約

| テーブル | 制約 | 意図 |
|---|---|---|
| users | UNIQUE (clerk_user_id) | Clerk アカウントの重複防止 |
| users | UNIQUE (username) | ユーザー名の一意性 |
| books | UNIQUE (google_books_id) | 同一書籍の重複登録防止 |
| user_books | UNIQUE (user_id, book_id) | 同じ本を複数回投稿不可 |
| follows | UNIQUE (follower_id, followee_id) | 重複フォロー防止 |
| likes | UNIQUE (user_id, user_book_id) | 同じ投稿への重複いいね防止 |
| tags | UNIQUE (name) | タグ名の一意性 |
| user_book_tags | UNIQUE (user_book_id, tag_id) | 同一投稿への重複タグ付与防止 |
| tag_follows | UNIQUE (user_id, tag_id) | 重複タグフォロー防止 |

---

## 設計上のポイント

### Books テーブルはキャッシュとして機能する

書籍データは Google Books API から取得しますが、初回登録時に Books テーブルに保存します。
これにより「この本を読んだユーザー一覧」などの集計クエリを DB 内で完結させます。

```sql
-- 特定の書籍を登録しているユーザー一覧
SELECT users.*
FROM users
INNER JOIN user_books ON users.id = user_books.user_id
WHERE user_books.book_id = :book_id;
```

### フォローベースのフィード

フィードは follows テーブルを使ってフォロー中ユーザーの投稿を取得します。

```sql
-- フォロー中ユーザーの投稿一覧（フィード）
SELECT user_books.*
FROM user_books
WHERE user_books.user_id IN (
  SELECT followee_id FROM follows WHERE follower_id = :current_user_id
)
ORDER BY user_books.created_at DESC;
```

このクエリの効率化のため、`user_books` に複合インデックス `INDEX (user_id, created_at DESC)` を設けています。
`IN` 句によるユーザー絞り込みと `ORDER BY created_at DESC` の両方をカバーします。

### 削除ポリシー

ユーザーデータは**物理削除**とし、論理削除（`deleted_at` カラム等）は使用しません。

ユーザー削除時はアプリケーション層でトランザクション内の順次削除を行います。削除順序は以下の通りです（FK 制約の依存関係に従う）。

```
likes
  → follows
  → tag_follows
    → refresh_tokens
      → user_links
        → user_book_purchase_links
          → user_book_tags
            → user_books
              → users
```

`books`・`tags` テーブルは他ユーザーも参照する共有データのため、ユーザー削除時には削除しません。

#### FK の ON DELETE 動作

全ての外部キーは **ON DELETE RESTRICT** とします。CASCADE は使用しません。

アプリケーション層で上記の順序を明示的に制御するため、DB 側での自動削除は行わない設計です。RESTRICT を設定することで、削除順序を誤った実装を DB レベルで検知できます。

| テーブル | FK カラム | 参照先 | ON DELETE |
|---|---|---|---|
| user_books | user_id | users | RESTRICT |
| user_books | book_id | books | RESTRICT |
| user_links | user_id | users | RESTRICT |
| user_book_purchase_links | user_book_id | user_books | RESTRICT |
| follows | follower_id | users | RESTRICT |
| follows | followee_id | users | RESTRICT |
| likes | user_id | users | RESTRICT |
| likes | user_book_id | user_books | RESTRICT |
| refresh_tokens | user_id | users | RESTRICT |
| user_book_tags | user_book_id | user_books | RESTRICT |
| user_book_tags | tag_id | tags | RESTRICT |
| tag_follows | user_id | users | RESTRICT |
| tag_follows | tag_id | tags | RESTRICT |

---

### 購入リンクの拡張性

現在は1件運用ですが、`user_book_purchase_links` を別テーブルにすることで
複数リンク対応への移行をアプリケーションコードの変更なく実現できます。

---

## 関連ドキュメント

- [システム概要](./overview.md)
- [認証フロー](./auth.md)
