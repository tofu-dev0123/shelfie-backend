# データモデル

## ER図

```
┌──────────────┐       ┌──────────────────┐       ┌──────────────────────────┐
│  user_links  │       │    user_books    │  1:N  │ user_book_purchase_links │
├──────────────┤       ├──────────────────┤       ├──────────────────────────┤
│ id           │       │ id               │───────│ id                       │
│ user_id      │  N:1  │ user_id          │       │ user_book_id             │
│ url          │       │ book_id          │       │ label                    │
└──────┬───────┘       │ summary          │       │ url                      │
       │               │ review           │       └──────────────────────────┘
       │               └──┬───────────┬───┘
       │ N:1              │ N:1       │ 1:N
┌──────▼───────┐          │       ┌───▼──────┐
│    users     │──────────┘       │  likes   │
├──────────────┤                  ├──────────┤
│ id           │  1:N             │ id       │
│ google_uid   │◄─────────────────│ user_id  │
│ email        │                  │ user_    │
│ nickname     │                  │ book_id  │
│ username     │                  └──────────┘
│ avatar_url   │
│ bio          │  follows
└──────┬───────┘  ┌──────────────┐
       │          │ follower_id  │──► users
       │          │ followee_id  │──► users
       │          └──────────────┘
       │
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
| [follows](./tables/follows.md) | フォロー関係 |
| [likes](./tables/likes.md) | いいね |
| [refresh_tokens](./tables/refresh_tokens.md) | リフレッシュトークン管理 |

---

## 主なユニーク制約

| テーブル | 制約 | 意図 |
|---|---|---|
| users | UNIQUE (google_uid) | Google アカウントの重複防止 |
| users | UNIQUE (username) | ユーザー名の一意性 |
| books | UNIQUE (google_books_id) | 同一書籍の重複登録防止 |
| user_books | UNIQUE (user_id, book_id) | 同じ本を複数回投稿不可 |
| follows | UNIQUE (follower_id, followee_id) | 重複フォロー防止 |
| likes | UNIQUE (user_id, user_book_id) | 同じ投稿への重複いいね防止 |

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

### 購入リンクの拡張性

現在は1件運用ですが、`user_book_purchase_links` を別テーブルにすることで
複数リンク対応への移行をアプリケーションコードの変更なく実現できます。

---

## 関連ドキュメント

- [システム概要](./overview.md)
- [認証フロー](./auth.md)
- [外部サービス連携](./external-services.md)
