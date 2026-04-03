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
│   ├── token_issuer.rb
│   └── cursor.rb
└── spec/
```

## 各ディレクトリの詳細

### app/controllers/

リクエストを受け取り、Serviceを1つ呼び、レスポンスを返す。ビジネスロジックは書かない。

- `v1/me/` 配下はすべて `V1::Me::BaseController` を継承し、全アクションで認証必須となる
- それ以外は認証不要（`/v1/feed` のみオプション認証を個別に適用）

```
app/controllers/
├── application_controller.rb
└── v1/
    ├── base_controller.rb             # v1共通処理
    ├── users_controller.rb            # GET /v1/users/:username
    │                                  # POST /v1/users
    │                                  # GET /v1/users/username/check
    ├── books_controller.rb            # GET /v1/books/search
    │                                  # GET /v1/books/:google_books_id
    │                                  # GET /v1/books/:google_books_id/users
    ├── user_books_controller.rb       # GET /v1/users/:username/books
    │                                  # GET /v1/users/:username/books/:google_books_id
    ├── follows_controller.rb          # GET /v1/users/:username/followers
    │                                  # GET /v1/users/:username/following
    ├── feed_controller.rb             # GET /v1/feed
    ├── auth/
    │   └── sessions_controller.rb    # POST /v1/auth/login
    │                                  # POST /v1/auth/refresh
    │                                  # DELETE /v1/auth/logout
    └── me/
        ├── base_controller.rb        # before_action :authenticate_user!
        ├── profiles_controller.rb    # GET /v1/me
        │                             # PATCH /v1/me
        ├── avatars_controller.rb     # POST /v1/me/avatar
        │                             # DELETE /v1/me/avatar
        ├── books_controller.rb       # POST /v1/me/books
        │                             # PATCH /v1/me/books/:google_books_id
        │                             # DELETE /v1/me/books/:google_books_id
        ├── follows_controller.rb     # POST /v1/me/follows/:username
        │                             # DELETE /v1/me/follows/:username
        └── likes_controller.rb       # POST /v1/me/likes/:username/:google_books_id
                                      # DELETE /v1/me/likes/:username/:google_books_id
```

### app/models/

バリデーション、アソシエーション、単一モデル内で完結するスコープを定義する。

複数テーブルをまたぐ複雑なクエリは `queries/` に切り出す。

```
app/models/
├── user.rb
├── book.rb
├── user_book.rb
├── user_book_purchase_link.rb
├── user_link.rb
├── follow.rb
├── like.rb
├── refresh_token.rb
└── queries/
    ├── feed_query.rb           # follows → user_books → users の結合 + カーソルページネーション
    └── book_readers_query.rb   # books → user_books → users の結合
```

### app/serializers/

モデルのデータをレスポンス用のJSONに変換する。gemは使わず素のRubyクラスで実装する。

```
app/serializers/
├── user_serializer.rb          # ユーザープロフィール全体（GET /v1/me, GET /v1/users/:username）
├── user_profile_serializer.rb  # プロフィール更新レスポンス（PATCH /v1/me）
├── book_serializer.rb
└── user_book_serializer.rb
```

### app/services/

1操作 = 1Serviceクラス。Controllerから呼ばれるビジネスロジックを担う。

Serviceの内部ではClient・Model・Query Object・`lib/` のユーティリティを呼ぶ。ServiceがServiceを呼ぶのは原則避ける。

```
app/services/
├── auth/
│   ├── login_service.rb          # Clerk検証 → JWT発行 → refresh_token保存
│   ├── refresh_service.rb        # refresh_token検証 → アクセストークン再発行
│   └── logout_service.rb         # refresh_token削除
├── users/
│   ├── create_service.rb         # Clerk検証 → User作成 → JWT発行
│   ├── show_service.rb           # ユーザープロフィール取得
│   ├── check_username_service.rb # username重複チェック
│   ├── me_show_service.rb        # 自分のプロフィール取得
│   └── me_update_service.rb      # 自分のプロフィール更新
└── user_books/
    ├── create_service.rb         # Google Books取得 → books upsert → user_book作成
    └── update_service.rb         # user_book更新 + purchase_links全置換
```

### lib/clients/

外部APIおよびクラウドサービスとの通信処理のみを担う。ビジネスロジックは書かない。

```
lib/clients/
├── clerk_client.rb           # Clerk JWT検証
├── google_books_client.rb    # Google Books API
└── s3_client.rb              # S3 ファイルアップロード
```

### lib/（直下）

DBや外部APIに依存しない共通ユーティリティ。

```
lib/
├── token_issuer.rb   # JWT生成・パース
└── cursor.rb         # カーソルのBase64エンコード・デコード
```

### config/

Railsの設定ファイル群。主な設定ファイルを記載する。

```
config/
├── routes.rb          # ルーティング定義
├── database.yml       # DB接続設定
├── storage.yml        # ActiveStorage（S3）設定
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
| 単一モデル内のCRUD | Controller → Model 直接 |
| 複数テーブルをまたぐ複雑なクエリ | Query Object（`app/models/queries/`） |
| 単一モデル内のクエリ | Model のスコープ |
| レスポンスJSON組み立て | Serializer |
| 外部APIとの通信 | Client（`lib/clients/`） |
| DBや外部APIに依存しない共通ロジック | `lib/` 直下 |
| ファイルストレージ（S3） | `S3Client`（`lib/clients/s3_client.rb`） |
