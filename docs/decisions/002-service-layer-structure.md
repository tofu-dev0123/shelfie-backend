# 002: サービス層・ディレクトリ構成

## 決定日

2026-03-06

## ステータス

決定済み

## 背景

Controller を薄く保ち、ビジネスロジック・DB操作・外部API通信・ユーティリティの責務を明確に分離するため、各レイヤーの置き場と役割を定める必要があった。

## 決定内容

### レイヤーの役割

| レイヤー | 置き場 | 役割 |
|---|---|---|
| Controller | `app/controllers/` | リクエスト受け取り → Serviceを1つ呼ぶ → レスポンスを返す |
| Service | `app/services/` | 1操作 = 1Serviceクラス。ビジネスロジックを担う |
| Model | `app/models/` | バリデーション、アソシエーション、単一モデル内で完結するスコープ |
| Query Object | `app/models/queries/` | 複数モデルをまたぐ複雑なクエリ |
| Client | `lib/clients/` | 外部APIとの通信 |
| ユーティリティ | `lib/` 直下 | DBや外部APIに依存しない共通ロジック |

### ディレクトリ構成

```
app/
├── controllers/
│   └── v1/
│       ├── base_controller.rb
│       ├── users_controller.rb
│       ├── books_controller.rb
│       ├── user_books_controller.rb
│       ├── follows_controller.rb
│       ├── feed_controller.rb
│       ├── auth/
│       │   └── sessions_controller.rb
│       └── me/
│           ├── base_controller.rb
│           ├── books_controller.rb
│           ├── follows_controller.rb
│           └── likes_controller.rb
├── models/
│   ├── user.rb
│   ├── book.rb
│   ├── user_book.rb
│   └── queries/
│       ├── feed_query.rb
│       └── book_readers_query.rb
└── services/
    ├── auth/
    │   ├── login_service.rb
    │   ├── refresh_service.rb
    │   └── logout_service.rb
    ├── users/
    │   └── create_service.rb
    └── user_books/
        ├── create_service.rb
        └── update_service.rb

lib/
├── clients/
│   ├── clerk_client.rb
│   └── google_books_client.rb
├── token_issuer.rb
└── cursor.rb
```

## 各レイヤーの判断基準

### Service化する基準

- 複数のモデルを操作する
- 外部APIを呼ぶ
- 上記に該当しない単純なCRUDはControllerからModelを直接操作する

### Query Objectにする基準

- 複数のモデル（テーブル）をまたぐクエリ → `app/models/queries/`
- 単一モデル内で完結するクエリ → Modelのスコープ

Query Objectを `app/models/queries/` に置く理由は、DB操作という性質上モデルに近い場所が自然であり、かつどのモデルに書くか迷わないようにするため。

### このプロジェクトでのQuery Object対象

| クエリ | 理由 |
|---|---|
| `FeedQuery` | follows → user_books → books → users の複数テーブル結合 + カーソルページネーション |
| `BookReadersQuery` | books → user_books → users の複数テーブル結合 |

### Clientにする基準

- 外部APIとの通信処理 → `lib/clients/`
- このプロジェクトでは Clerk（JWT検証）と Google Books API が該当

### ユーティリティにする基準

- DBや外部APIに依存しない純粋なロジック → `lib/` 直下
- このプロジェクトでは JWT生成・パース（`token_issuer.rb`）、カーソルのBase64エンコード・デコード（`cursor.rb`）が該当

## 呼び出し関係

```
Controller
  └── Service を1つだけ呼ぶ
        ├── Client を呼ぶ（外部API通信）
        ├── Model を操作する
        ├── Query Object を呼ぶ（複雑なクエリ）
        └── lib/ のユーティリティを呼ぶ
```
