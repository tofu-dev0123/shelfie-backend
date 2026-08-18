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
    │   └── V1::Me::ProfilesController
    └── （公開系コントローラー）
        ├── V1::UsersController
        ├── V1::BooksController
        ├── V1::UserBooksController
        └── V1::Auth::SessionsController
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
    ├── auth/
    │   └── sessions_controller.rb
    └── me/
        ├── base_controller.rb
        ├── books_controller.rb
        └── profiles_controller.rb
```

## 理由

- `app/controllers/v1/me/` 配下にあれば「全アクション認証必須」、それ以外は「認証不要」と、**ファイルの場所だけで認証要否が判断できる**
- `V1::Me::BaseController` に `before_action :authenticate_user!` を1箇所に書くだけで、配下の全コントローラー・全アクションに適用できる
- 後からコントローラーを追加する際も、`me/` に置くか否かのルールが明確で迷わない

## 例外

### 1. `v1/` 直下で認証必須にするエンドポイント

`GET /v1/books/search` と `GET /v1/books/:isbn` は楽天書籍APIのリクエスト制限対策のため、`v1/` 直下ながら `V1::BooksController` に個別で `before_action :authenticate_user!` を適用する。オプション認証（トークンがある場合のみ認証）は使用しない。

### 2. `/v1` の外に置くコントローラ（`OauthController`）

**追記日: 2026-08-10（issue #146）**

OAuth の入口2本は `/v1` の名前空間の外に置き、`V1::BaseController` を継承しない。

```
ApplicationController
├── OauthController                 # GET /auth/:provider
│                                   # GET /auth/:provider/callback
└── V1::BaseController
```

`app/controllers/oauth_controller.rb`（`v1/` 配下ではない）。

**理由: これは JSON API ではない。**

| | `/v1` 配下 | `OauthController` |
|---|---|---|
| 呼び出し元 | フロントの `fetch` | **ブラウザのトップレベル遷移**（リンククリック / IdP からの 302） |
| 成功時の返し方 | `render json:` | **302 リダイレクト** |
| 失敗時の返し方 | `ErrorHandler` が JSON エラー | **302 リダイレクト**（`/login?error=...`） |
| バージョニング | `/v1` で固定 | **対外契約はリダイレクト先とエラーコード**であり、JSON スキーマを持たない |

`ErrorHandler` を include しないのは、**全例外を JSON で返してしまうと
生の JSON がページとして表示される**ため。ユーザーはブラウザで直接この URL を見ている。

そのため `Oauth::CallbackService` は失敗を例外で返さず、すべてエラーコードに畳んで返す。
Controller 側はリダイレクトだけを行う。

`/v1` を付けない理由は、このエンドポイントの契約が JSON スキーマではなく
**リダイレクト先とエラーコードの集合**であり、API バージョンと独立して変化するため。
契約値（`/` `/signup` `/login`）は Controller の定数に置き、
[docs/api/oauth/callback.md](../api/oauth/callback.md) に記載する。

判断基準 → **ブラウザのトップレベル遷移で叩かれるなら `/v1` の外。**
`fetch` で叩かれるなら `/v1` 配下。

認証方式そのものの決定 → [009: 認証方式](./009-authentication.md)
