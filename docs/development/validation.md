# バリデーション処理

## 処理フロー

バリデーションはModelの `save!` / `create!` が呼ばれたタイミングで実行される。
リクエストを受け取った段階（Controller・Service）では実行されない。

```
Controller（Strong Parameters でパラメータをフィルタ）
  ↓
Service（ビジネスロジック）
  ↓
Model.create! / save!  ← ここでバリデーション実行
  ↓ 失敗
ActiveRecord::RecordInvalid を raise
  ↓
ErrorHandler がキャッチ → レスポンスに変換
```

## バリデーションの仕組み

### ルールの定義

`validates` でルールを定義するだけでよい。開発者が明示的に例外を raise する必要はない。

```ruby
class User < ApplicationRecord
  validates :username, presence: true, uniqueness: true
  validates :nickname, presence: true, length: { maximum: 50 }
end
```

### valid? による全件チェック

`save!` は内部で `valid?` を呼び出す。`valid?` は**全てのバリデーションルールを最後まで実行**してから `errors` にエラーを積む。最初のエラーで止まるわけではない。

```ruby
user = User.new(username: "", nickname: "")
user.valid?  # 全ルールを実行してから false を返す

user.errors.map { |err| { field: err.attribute, message: err.full_message } }
# => [
#   { field: :username, message: "ユーザー名は必須です" },
#   { field: :nickname, message: "ニックネームは必須です" }
# ]
```

### 例外に全エラーが乗る

`valid?` が false の場合、`save!` はモデルオブジェクトごと例外に乗せて raise する。

```ruby
# Rails の内部実装（イメージ）
def save!
  if valid?
    # INSERT INTO ...
  else
    raise ActiveRecord::RecordInvalid.new(self)  # self = 全エラーを持つモデルオブジェクト
  end
end
```

## ErrorHandler によるキャッチ

`rescue_from` は Controller のアクション全体を包んでいるため、Service の中から伝播してきた例外も自動でキャッチする。

```ruby
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  end

  private

  def render_unprocessable_entity(e)
    details = e.record.errors.map do |error|
      {
        field: error.attribute,
        message: error.full_message  # 属性の日本語名 + エラーメッセージ
      }
    end

    render json: {
      error: {
        code: "UNPROCESSABLE_ENTITY",
        message: "入力内容に誤りがあります",
        details: details
      }
    }, status: :unprocessable_entity
  end
end
```

### e.record について

| プロパティ | 内容 |
|---|---|
| `e.record` | バリデーションに失敗したモデルオブジェクト |
| `e.record.errors` | 全バリデーションエラーのコレクション |
| `error.attribute` | エラーが発生したフィールド名（例: `:username`） |
| `error.message` | エラーメッセージのみ（例: `"は必須です"`） |
| `error.full_message` | 属性の日本語名 + メッセージ（例: `"ユーザー名は必須です"`） |

## エラーメッセージの定義

エラーメッセージはモデルに直接書かず、`config/locales/ja.yml` に集約する。

### 属性の日本語名

`full_message` で使われる。ここで定義した名前がメッセージの先頭に付く。

```yaml
ja:
  activerecord:
    attributes:
      user:
        username: "ユーザー名"
        nickname: "ニックネーム"
        bio:      "自己紹介"
```

### エラーメッセージ

バリデーションルールごとに対応するi18nキーが決まっている。

```yaml
ja:
  activerecord:
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

`%{count}` はRailsが自動で数値に置き換える。

### バリデーションルールとi18nキーの対応

| バリデーション | i18nキー |
|---|---|
| `presence: true` | `blank` |
| `uniqueness: true` | `taken` |
| `length: { maximum: N }` | `too_long` |
| `length: { minimum: N }` | `too_short` |
| `format: { with: /.../ }` | `invalid` |
| `numericality` | `not_a_number` |
| `inclusion: { in: [...] }` | `inclusion` |

## Service での方針

Serviceはバリデーションエラーを `rescue` しない。`!` 付きメソッドで raise させてそのまま伝播させ、ErrorHandler に一任する。

```ruby
class Users::CreateService
  def self.call(params)
    User.create!(params)  # バリデーション失敗時はそのまま raise される
  end
end
```

## 開発者がやることのまとめ

| やること | 場所 |
|---|---|
| バリデーションのルールを定義する | Model |
| 属性の日本語名を定義する | `config/locales/ja.yml` |
| エラーメッセージを定義する | `config/locales/ja.yml` |
| `!` 付きメソッドで保存する | Service |
| 例外をキャッチしてレスポンスに変換する | ErrorHandler |

例外の raise とエラーメッセージの紐づけはRailsが自動でおこなう。
