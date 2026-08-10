# データモデル

## ER図

```
┌──────────────────┐  ┌──────────────┐  ┌────────────────┐  ┌──────────────────┐
│ user_identities  │  │  user_links  │  │ refresh_tokens │  │    user_books    │
├──────────────────┤  ├──────────────┤  ├────────────────┤  ├──────────────────┤
│ id               │  │ id           │  │ id             │  │ id               │
│ user_id          │  │ user_id      │  │ user_id        │  │ user_id          │
│ provider         │  │ url          │  │ token          │  │ book_id          │
│ provider_uid     │  └──────┬───────┘  │ expires_at     │  │ content          │
│ email            │         │          └────────┬───────┘  └────────┬─────────┘
└────────┬─────────┘         │ N:1               │ N:1               │ N:1
         │ N:1               │                   │                   │
         └───────────────────┴─────────┬─────────┴───────────────────┘
                                       │
                              ┌────────▼───────┐
                              │     users      │
                              ├────────────────┤
                              │ id             │
                              │ email          │
                              │ nickname       │
                              │ username       │
                              │ bio            │
                              └────────────────┘

                      ┌──────────────┐
   user_books ── N:1 ─│    books     │
                      ├──────────────┤
                      │ id / isbn    │
                      │ title        │
                      │ authors[]    │
                      └──────────────┘
```

---

## テーブル一覧

| テーブル | 用途 |
|---|---|
| [users](./tables/users.md) | ユーザーのプロフィール情報 |
| [user_identities](./tables/user_identities.md) | 外部プロバイダ（Google / GitHub）との連携 |
| [user_links](./tables/user_links.md) | プロフィールリンク（最大5件）|
| [books](./tables/books.md) | 書籍データ（楽天書籍API キャッシュ）|
| [user_books](./tables/user_books.md) | 本棚投稿 |
| [refresh_tokens](./tables/refresh_tokens.md) | リフレッシュトークン管理 |

---

## 主なユニーク制約

| テーブル | 制約 | 意図 |
|---|---|---|
| users | UNIQUE (email) | 連絡先メールの一意性。同一メールで別プロバイダが来たときの拒否判定（P1）に使う |
| users | UNIQUE (username) | ユーザー名の一意性 |
| user_identities | UNIQUE (provider, provider_uid) | 同じ外部 ID が2ユーザーに紐づかない |
| user_identities | UNIQUE (user_id, provider) | 同一プロバイダの二重連携を防ぐ |
| books | UNIQUE (isbn) | 同一書籍の重複登録防止 |
| user_books | UNIQUE (user_id, book_id) | 同じ本を複数回投稿不可 |

---

## 設計上のポイント

### Books テーブルはキャッシュとして機能する

書籍データは楽天書籍APIから取得しますが、初回登録時に Books テーブルに保存します。
これにより「この本を読んだユーザー一覧」などの集計クエリを DB 内で完結させます。

```sql
-- 特定の書籍を登録しているユーザー一覧
SELECT users.*
FROM users
INNER JOIN user_books ON users.id = user_books.user_id
WHERE user_books.book_id = :book_id;
```

### 本棚一覧のインデックス

`user_books` には複合インデックス `INDEX (user_id, created_at DESC)` を設けています。
「特定ユーザーの本棚を新着順に取得する」というアクセスパターンを、ユーザー絞り込みと `ORDER BY created_at DESC` の両面でカバーします。

```sql
-- 特定ユーザーの本棚一覧（新着順）
SELECT user_books.*
FROM user_books
WHERE user_books.user_id = :user_id
ORDER BY user_books.created_at DESC, user_books.id DESC;
```

### 削除ポリシー

ユーザーデータは**物理削除**とし、論理削除（`deleted_at` カラム等）は使用しません。

ユーザー削除時はアプリケーション層でトランザクション内の順次削除を行います。削除順序は以下の通りです（FK 制約の依存関係に従う）。

```
refresh_tokens
  → user_identities
    → user_links
      → user_books
        → users
```

`books` テーブルは他ユーザーも参照する共有データのため、ユーザー削除時には削除しません。

#### FK の ON DELETE 動作

全ての外部キーは **ON DELETE RESTRICT** とします。CASCADE は使用しません。

アプリケーション層で上記の順序を明示的に制御するため、DB 側での自動削除は行わない設計です。RESTRICT を設定することで、削除順序を誤った実装を DB レベルで検知できます。

| テーブル | FK カラム | 参照先 | ON DELETE |
|---|---|---|---|
| user_books | user_id | users | RESTRICT |
| user_books | book_id | books | RESTRICT |
| user_links | user_id | users | RESTRICT |
| user_identities | user_id | users | RESTRICT |
| refresh_tokens | user_id | users | RESTRICT |

---

## 関連ドキュメント

- [システム概要](./overview.md)
- [認証フロー](./auth.md)
