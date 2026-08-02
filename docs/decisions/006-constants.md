# 006: 定数管理方針

## 決定日

2026-03-06

## ステータス

決定済み

## 決定内容

### 種類ごとの置き場

| 種類 | 置き場 |
|---|---|
| バリデーションエラーメッセージ | `config/locales/activerecord/` にモデルごとのyml |
| エラーコード | `app/constants/error_codes.rb` |
| 固定エラーメッセージ | `app/constants/messages.rb` |
| 成功メッセージ | `app/constants/messages.rb` |
| 実装の定数 | `app/constants/` に種類ごとのファイル |

### バリデーションエラーメッセージはモデルごとにymlで管理する

`config/locales/` 以下は再帰的に自動ロードされるため、サブディレクトリに分けても動作は変わらない。モデルが増えても1ファイルが肥大化しないようモデルごとにファイルを分ける。

```
config/locales/
└── activerecord/
    ├── user.ja.yml
    ├── book.ja.yml
    └── user_book.ja.yml
```

### 成功メッセージ・エラーコードはRuby定数で管理する

多言語対応の予定がないため、i18nではなくRuby定数として `app/constants/` に置く。Railsのオートロード対象のため `require` 不要。

```ruby
# app/constants/error_codes.rb
module ErrorCodes
  UNAUTHORIZED        = "UNAUTHORIZED"
  NOT_FOUND           = "NOT_FOUND"
  UNPROCESSABLE_ENTITY = "UNPROCESSABLE_ENTITY"
  BAD_REQUEST         = "BAD_REQUEST"
end

# app/constants/messages.rb
module Messages
  BOOK_DESTROYED = "削除が完了しました"
end
```

### Ruby定数を採用した理由

- 日本語固定のAPIサーバーのため多言語対応は不要
- `I18n.t(...)` の呼び出しが不要でシンプル
- タイポがあればRuby起動時に気づける
- 定数なので参照箇所でIDEの補完が効く
