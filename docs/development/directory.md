# ディレクトリ構成

## 全体構成

```
shelfie-backend/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── serializers/
│   └── services/
├── config/
├── db/
├── docs/
├── lib/
│   ├── clients/
│   ├── oauth/
│   ├── token_issuer.rb
│   ├── cursor.rb
│   ├── id_cursor.rb
│   └── compound_cursor.rb
└── spec/
```

## 各ディレクトリの詳細

### app/controllers/

リクエストを受け取り、Serviceを1つ呼び、レスポンスを返す。ビジネスロジックは書かない。

- `v1/me/` 配下はすべて `V1::Me::BaseController` を継承し、全アクションで認証必須となる
- それ以外はアクセストークンによる認証不要（Cookie で認証するものはある。下記 `oauth_controller.rb` / `v1/auth/signups_controller.rb`）
- 例外: `GET /v1/books/search` と `GET /v1/books/:isbn` は楽天書籍APIのリクエスト制限対策のため、`v1/` 直下ながら認証必須（`before_action :authenticate_user!` を個別に適用）

```
app/controllers/
├── application_controller.rb
├── oauth_controller.rb                # GET /auth/:provider
│                                      # GET /auth/:provider/callback
├── concerns/
│   ├── error_handler.rb              # 例外 → JSON エラーレスポンス
│   ├── refresh_token_cookie.rb       # refresh_token Cookie の set / clear
│   ├── oauth_state_cookie.rb         # oauth_state Cookie の set / clear
│   └── signup_token_cookie.rb        # signup_token Cookie の set / clear
└── v1/
    ├── base_controller.rb             # v1共通処理
    ├── users_controller.rb            # GET /v1/users/:username
    │                                  # POST /v1/users
    │                                  # GET /v1/users/username/check
    ├── books_controller.rb            # GET /v1/books/search
    │                                  # GET /v1/books/:isbn
    │                                  # GET /v1/books/:isbn/users
    ├── user_books_controller.rb       # GET /v1/users/:username/books
    │                                  # GET /v1/users/:username/books/:isbn
    ├── auth/
    │   ├── sessions_controller.rb    # POST /v1/auth/refresh
    │   │                             # DELETE /v1/auth/logout
    │   └── signups_controller.rb     # GET /v1/auth/signup_context
    └── me/
        ├── base_controller.rb        # before_action :authenticate_user!
        ├── profiles_controller.rb    # GET /v1/me
        │                             # PATCH /v1/me
        └── books_controller.rb       # POST /v1/me/books
                                      # PUT /v1/me/books/:isbn
                                      # DELETE /v1/me/books/:isbn
```

`oauth_controller.rb` だけは **`V1::BaseController` を継承せず、`ErrorHandler` も通さない**。
ブラウザのトップレベル遷移で叩かれるため、JSON を返すと生の JSON がページとして表示される。
成否によらず 302 リダイレクトで返す（詳細は `docs/api/oauth/callback.md`）。

### app/models/

バリデーション、アソシエーション、単一モデル内で完結するスコープを定義する。

複数テーブルをまたぐ複雑なクエリは `queries/` に切り出す。

```
app/models/
├── user.rb
├── user_identity.rb            # 外部プロバイダとの連携（provider, provider_uid）
├── book.rb
├── user_book.rb
├── user_link.rb
├── refresh_token.rb
└── queries/
    └── book_readers_query.rb   # books → user_books → users の結合
```

### app/serializers/

モデルのデータをレスポンス用のJSONに変換する。gemは使わず素のRubyクラスで実装する。

```
app/serializers/
├── user_serializer.rb            # ユーザープロフィール全体（GET /v1/me, GET /v1/users/:username）
├── user_profile_serializer.rb    # プロフィール更新レスポンス（PATCH /v1/me）
├── user_summary_serializer.rb    # ユーザー要約（GET /v1/books/:isbn/users）
├── user_book_serializer.rb       # 本棚一覧の1件（GET /v1/users/:username/books）
└── user_book_show_serializer.rb  # 本棚投稿詳細（GET /v1/users/:username/books/:isbn）
```

### app/services/

1操作 = 1Serviceクラス。Controllerから呼ばれるビジネスロジックを担う。

Serviceの内部ではClient・Model・Query Object・`lib/` のユーティリティを呼ぶ。ServiceがServiceを呼ぶのは原則避ける。

```
app/services/
├── oauth/
│   ├── start_service.rb          # state/PKCE発行 → 認可URL組立
│   └── callback_service.rb       # state照合 → コード交換 → ログイン/サインアップ分岐
├── auth/
│   ├── signup_context_service.rb # signup_token検証 → サインアップ画面の初期表示情報
│   ├── refresh_service.rb        # refresh_token検証 → アクセストークン再発行
│   └── logout_service.rb         # refresh_token削除
├── users/
│   ├── create_service.rb         # signup_token検証 → User+UserIdentity+refresh_token作成 → JWT発行
│   ├── show_service.rb           # ユーザープロフィール取得
│   ├── check_username_service.rb # username重複チェック
│   ├── me_show_service.rb        # 自分のプロフィール取得
│   └── me_update_service.rb      # 自分のプロフィール更新
├── books/
│   ├── search_service.rb         # 楽天書籍API検索
│   ├── show_service.rb           # ISBN指定で書籍取得
│   └── readers_service.rb        # 書籍を登録しているユーザー一覧
└── user_books/
    ├── index_service.rb          # 本棚一覧取得
    ├── show_service.rb           # 本棚投稿詳細取得
    ├── create_service.rb         # 楽天書籍API取得 → books upsert → user_book作成
    ├── update_service.rb         # user_book更新
    └── destroy_service.rb        # user_book削除
```

### lib/clients/

外部APIおよびクラウドサービスとの通信処理のみを担う。ビジネスロジックは書かない。

```
lib/clients/
└── rakuten_books_client.rb   # 楽天書籍API
```

### lib/oauth/

OAuth プロバイダとの通信と、プロバイダ差の吸収を担う。
**プロバイダごとの違いはこの層に閉じる。** ここより上（`app/services/oauth/**`・`OauthController`）に
`google` / `github` という名前が出てきたら設計が崩れているサイン。

```
lib/oauth/
├── providers.rb              # 許可プロバイダのレジストリ（名前 → クラス解決）
├── providers/
│   ├── base.rb              # 認可URL組立・コード交換の共通処理
│   ├── google.rb            # id_token の iss/aud/exp/email_verified 検証
│   └── github.rb            # /user と /user/emails から Identity を組み立て
├── identity.rb               # プロバイダ差を吸収したあとの本人情報
├── state.rb                  # state と PKCE の往復データ（署名付き Cookie）
├── provider_error.rb
├── email_unavailable_error.rb
└── unsupported_provider_error.rb
```

### lib/（直下）

DBや外部APIに依存しない共通ユーティリティ。

```
lib/
├── token_issuer.rb       # JWT生成・パース（access / refresh / signup）
├── cursor.rb             # カーソルのBase64エンコード・デコード
├── id_cursor.rb          # id 単一キーのカーソル
└── compound_cursor.rb    # (created_at, id) 複合キーのカーソル
```

### config/

Railsの設定ファイル群。主な設定ファイルを記載する。

```
config/
├── routes.rb          # ルーティング定義
├── database.yml       # DB接続設定
└── initializers/
    └── cors.rb        # CORS設定
```

### db/

マイグレーションファイルとシードデータ。

```
db/
├── migrate/
└── seeds.rb
```

### spec/

RSpecによるテスト。

```
spec/
├── rails_helper.rb
├── spec_helper.rb
├── models/
├── services/
└── requests/          # APIエンドポイントのテスト
```

## 呼び出し関係

```
Controller
  └── Service を1つだけ呼ぶ
        ├── Client（外部API通信）
        ├── Model（DB操作）
        ├── Query Object（複数テーブルをまたぐクエリ）
        └── lib/ のユーティリティ
```

## 判断基準まとめ

| 処理の性質 | 置き場 |
|---|---|
| リクエスト受け取り・レスポンス返却 | Controller |
| 複数モデルをまたぐビジネスロジック・外部API呼び出し | Service |
| 単一モデル内のCRUD | Service → Model |
| 複数テーブルをまたぐ複雑なクエリ | Query Object（`app/models/queries/`） |
| 単一モデル内のクエリ | Model のスコープ |
| レスポンスJSON組み立て | Serializer |
| 外部APIとの通信 | Client（`lib/clients/`） |
| DBや外部APIに依存しない共通ロジック | `lib/` 直下 |
