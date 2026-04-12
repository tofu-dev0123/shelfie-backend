# 001: コントローラーのディレクトリ構成

## 決定日

2026-03-06

## ステータス

決定済み

## 背景

Rails API のコントローラー設計において、1つのリソースに対して「公開・認証不要」のエンドポイントと「認証必須」のエンドポイントが共存するケースがある。

例：本棚投稿（user_books）

```
GET    /v1/users/:username/books     # 認証不要
POST   /v1/me/books                  # 認証必須
PATCH  /v1/me/books/:isbn # 認証必須
DELETE /v1/me/books/:isbn # 認証必須
```

この場合、コントローラーをどのように分割・配置するかを決定する必要があった。

## 検討した案

### Case A: リソース中心（1リソース = 1コントローラー）

`UserBooksController` 1つに全アクションを集約する。`before_action :authenticate_user!, only: [:create, :update, :destroy]` のように `only:` で制御する。

**問題点:** 認証の有無がコードを読まないと分からず、管理が複雑になる。

### Case B: URLの名前空間に沿って分ける（採用）

`/v1/me/*` に対応するコントローラーを `v1/me/` 名前空間に分ける。

### Case C: 完全フラット

全コントローラーを `v1/` 直下に並べる。Case A 以上に before_action の管理が複雑になる。

## 決定内容

**Case B（URLの名前空間に沿った分割）を採用する。**

### コントローラーの継承構造

```
ApplicationController
└── V1::BaseController              # v1共通処理
    ├── V1::Me::BaseController      # before_action :authenticate_user!
    │   ├── V1::Me::BooksController
    │   ├── V1::Me::FollowsController
    │   └── V1::Me::LikesController
    └── （公開系コントローラー）
        ├── V1::UsersController
        ├── V1::BooksController
        ├── V1::UserBooksController
        ├── V1::FollowsController
        └── V1::FeedController      # オプション認証（例外）
```

### ディレクトリ構成

```
app/controllers/
├── application_controller.rb
└── v1/
    ├── base_controller.rb
    ├── users_controller.rb
    ├── books_controller.rb
    ├── user_books_controller.rb
    ├── follows_controller.rb
    ├── feed_controller.rb
    ├── auth/
    │   └── sessions_controller.rb
    └── me/
        ├── base_controller.rb
        ├── books_controller.rb
        ├── follows_controller.rb
        └── likes_controller.rb
```

## 理由

- `app/controllers/v1/me/` 配下にあれば「全アクション認証必須」、それ以外は「認証不要」と、**ファイルの場所だけで認証要否が判断できる**
- `V1::Me::BaseController` に `before_action :authenticate_user!` を1箇所に書くだけで、配下の全コントローラー・全アクションに適用できる
- 後からコントローラーを追加する際も、`me/` に置くか否かのルールが明確で迷わない

## 例外

`GET /v1/feed` はログイン状態で挙動が変わるオプション認証のため、`V1::FeedController` に個別で `authenticate_user_if_token_present!` を呼ぶ形とする。例外はこの1つのみ。
