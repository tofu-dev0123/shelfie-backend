# 005: バリデーション方針

## 決定日

2026-03-06

## ステータス

決定済み

## 決定内容

### バリデーションはModelに集約する

バリデーションはModelのみに書く。Serviceにはバリデーションロジックを持たせない。

```ruby
class User < ApplicationRecord
  validates :username, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }
  validates :nickname, presence: true, length: { maximum: 50 }
end
```

### DBの制約とModelのバリデーションを両方つける

| レイヤー | 役割 |
|---|---|
| DBの制約（NOT NULL・UNIQUE INDEX） | 最後の砦。データの整合性を絶対に保証する |
| Modelのバリデーション | 早期検出。分かりやすいエラーメッセージをレスポンスする |

重要な項目は両方つける。

### エラーメッセージはi18nで管理する

エラーメッセージはモデルに直接書かず、`config/locales/ja.yml` に集約する。

```yaml
# config/locales/ja.yml
ja:
  activerecord:
    errors:
      models:
        user:
          attributes:
            username:
              blank: "は必須です"
              taken: "はすでに使用されています"
              invalid: "は半角英数字・アンダースコアのみ使用できます"
            nickname:
              blank: "は必須です"
              too_long: "は50文字以内で入力してください"
```

### エラーハンドリングはErrorHandler Concernに集約する

`rescue_from` をBaseControllerに直接書かず、`ErrorHandler` Concern として独立したファイルに切り出す。`V1::BaseController` でincludeして使用する。

```ruby
# app/controllers/concerns/error_handler.rb
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid,        with: :render_unprocessable_entity
    rescue_from ActiveRecord::RecordNotFound,       with: :render_not_found
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
  end

  private

  def render_unprocessable_entity(e)
    render json: {
      error: {
        code: "UNPROCESSABLE_ENTITY",
        message: "入力内容に誤りがあります",
        details: e.record.errors.map { |err| { field: err.attribute, message: err.message } }
      }
    }, status: :unprocessable_entity
  end

  def render_not_found(e)
    render json: {
      error: { code: "NOT_FOUND", message: "リソースが見つかりません" }
    }, status: :not_found
  end
end

# app/controllers/v1/base_controller.rb
class V1::BaseController < ApplicationController
  include ErrorHandler
end
```

### ErrorHandler Concernを採用した理由

- エラー処理が独立したファイルに集約され、責務が明確になる
- BaseControllerをエラー処理で汚染しない
- ErrorHandler単体でテスト可能
- エラーパターンが増えても1ファイルに追記するだけで対応できる

## レスポンス形式

バリデーションエラー時は以下の形式で返す（API設計で定義済み）。

```json
// 422 Unprocessable Entity
{
  "error": {
    "code": "UNPROCESSABLE_ENTITY",
    "message": "入力内容に誤りがあります",
    "details": [
      { "field": "username", "message": "はすでに使用されています" },
      { "field": "nickname", "message": "は必須です" }
    ]
  }
}
```
