# ログ設計

## 概要

| 項目 | 方針 |
|---|---|
| 出力先 | 標準出力（stdout）→ Docker の json-file ドライバがキャプチャ |
| フォーマット | JSON形式（lograge） |
| ログビューア | SSM Session Manager で EC2 に接続し `docker logs` |
| 保持 | `max-size` 10m × 3 世代でローテーション |

## logrageの設定

```ruby
# config/initializers/lograge.rb
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.logger = ActiveSupport::Logger.new($stdout)

  config.lograge.custom_options = lambda do |event|
    { user_id: event.payload[:user_id] }
  end
end
```

```ruby
# app/controllers/v1/base_controller.rb
def append_info_to_payload(payload)
  super
  payload[:user_id] = current_user&.id
end
```

### リクエスト・レスポンスのログ（logrageが自動出力）

```json
{ "method": "GET", "path": "/v1/me", "status": 200, "duration": 12.3, "user_id": 123 }
{ "method": "GET", "path": "/v1/books/search", "status": 200, "duration": 8.1, "user_id": null }
```

## ログレベルの使い分け

| レベル | 使う場面 |
|---|---|
| `DEBUG` | メソッド入口ログ（本番以外のみ） |
| `INFO` | リクエスト・認証成功・外部API成功など正常な処理 |
| `WARN` | 認証失敗・外部APIエラーなど異常だが継続できる場合 |
| `ERROR` | 例外発生時など対応が必要なエラー |

## ログの書き方

Railsの `logger` を使う。

```ruby
Rails.logger.debug  "UsersController#create に入りました"
Rails.logger.info   "ログイン成功: user_id=#{user.id}"
Rails.logger.warn   "認証失敗: #{reason}"
Rails.logger.error  "例外発生: #{e.message}"
```

## 各種ログの実装例

### 例外発生時（ERROR）

ErrorHandlerで例外をキャッチしたタイミングで出力する。

```ruby
# app/controllers/concerns/error_handler.rb
def render_unprocessable_entity(e)
  Rails.logger.error "RecordInvalid: #{e.message}"
  # ...
end

def render_not_found(e)
  Rails.logger.error "RecordNotFound: #{e.message}"
  # ...
end
```

### 認証イベント（INFO / WARN）

```ruby
# app/services/oauth/callback_service.rb
Rails.logger.info  "ログイン成功: user_id=#{user.id}"
Rails.logger.info  "サインアップ導線へ遷移: provider=#{identity.provider}"
Rails.logger.warn  "コールバック失敗: state 検証に失敗 provider=#{provider}"
Rails.logger.warn  "コールバック失敗: プロバイダ起因 #{e.class} #{e.message}"
Rails.logger.error "コールバック失敗: 想定外の例外 #{e.class} #{e.message}"
```

**OAuth のコールバックは `ErrorHandler` を通さない**（失敗もリダイレクトで返すため）。
Service 側で出さないとどこにも残らないので、state 検証の失敗（CSRF 疑い）と
想定外の例外は必ずここで記録する。

**トークン・認可コード・`code_verifier` はログに出さない。**
`provider` と `user_id` までに留める。

### 外部API呼び出し（INFO / WARN）

```ruby
# lib/clients/rakuten_books_client.rb
Rails.logger.info "楽天書籍API 呼び出し開始"
Rails.logger.info "楽天書籍API 呼び出し成功: duration=#{duration}ms"
Rails.logger.warn "楽天書籍API 呼び出し失敗: #{e.message}"
```

### メソッド入口（DEBUG・本番以外のみ）

```ruby
def create
  Rails.logger.debug "UsersController#create に入りました"
  # ...
end
```

本番では `DEBUG` レベルのログは出力されない。環境ごとのログレベルは以下で設定する。

```ruby
# config/environments/production.rb
config.log_level = :info   # DEBUG は出力しない

# config/environments/development.rb
config.log_level = :debug  # DEBUG も出力する
```
