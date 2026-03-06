# 定数管理

## 置き場の一覧

| 種類 | 置き場 |
|---|---|
| バリデーションエラーメッセージ | `config/locales/activerecord/<model>.ja.yml` |
| エラーコード | `app/constants/error_codes.rb` |
| 固定エラーメッセージ・成功メッセージ | `app/constants/messages.rb` |
| 実装の定数 | `app/constants/<種類>.rb` |

## ディレクトリ構成

```
config/locales/
└── activerecord/
    ├── user.ja.yml
    ├── book.ja.yml
    └── user_book.ja.yml

app/constants/
├── error_codes.rb
└── messages.rb
```

## app/constants/

Railsのオートロード対象のため `require` 不要。

### error_codes.rb

ErrorHandlerで使用するエラーコード文字列を定数化する。

```ruby
module ErrorCodes
  UNAUTHORIZED         = "UNAUTHORIZED"
  NOT_FOUND            = "NOT_FOUND"
  UNPROCESSABLE_ENTITY = "UNPROCESSABLE_ENTITY"
  BAD_REQUEST          = "BAD_REQUEST"
end
```

### messages.rb

APIレスポンスに含める固定メッセージを定数化する。

```ruby
module Messages
  AVATAR_DELETED = "アバター画像を削除しました"
end
```

### Controllerでの使い方

```ruby
render json: { message: Messages::AVATAR_DELETED }

# ErrorHandlerでの使い方
render json: {
  error: {
    code: ErrorCodes::UNAUTHORIZED,
    message: "認証が必要です"
  }
}, status: :unauthorized
```

## config/locales/activerecord/

モデルのバリデーションメッセージはモデルごとにymlファイルで管理する。
`config/locales/` 以下は再帰的に自動ロードされるため、サブディレクトリに分けても動作は変わらない。

```yaml
# config/locales/activerecord/user.ja.yml
ja:
  activerecord:
    attributes:
      user:
        username: "ユーザー名"
        nickname: "ニックネーム"
        bio:      "自己紹介"
    errors:
      models:
        user:
          attributes:
            username:
              blank:     "は必須です"
              taken:     "はすでに使用されています"
              invalid:   "は半角英数字・アンダースコアのみ使用できます"
              too_short: "は%{count}文字以上で入力してください"
              too_long:  "は%{count}文字以内で入力してください"
            nickname:
              blank:     "は必須です"
              too_long:  "は%{count}文字以内で入力してください"
```

バリデーションルールとi18nキーの対応は `docs/development/validation.md` を参照。
