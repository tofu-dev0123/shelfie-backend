require "swagger_helper"

RSpec.describe "ユーザー系", type: :request do
  path "/v1/users" do
    post "ユーザー登録API" do
      tags "ユーザー系"
      consumes "application/json"
      produces "application/json"

      let(:identity) do
        Oauth::Identity.new(provider: "google", uid: "uid_123", email: "komu@example.com", name: "コムサン")
      end
      let(:signup_token) { TokenIssuer.issue_signup_token(identity) }

      parameter name: "Cookie", in: :header, type: :string, required: true,
        description: "`signup_token=<JWT>`（コールバックが発行した10分有効の Cookie）"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          nickname: { type: :string, example: "コムさん" },
          username: { type: :string, example: "komusan" }
        },
        required: [ "nickname", "username" ]
      }

      response "201", "ユーザー作成成功" do
        let(:Cookie) { "signup_token=#{signup_token}" }
        let(:body) { { nickname: "コムさん", username: "komusan" } }

        schema type: :object,
          properties: {
            access_token: { type: :string, example: "eyJ..." }
          },
          required: [ "access_token" ]

        # サインアップ直後の SSR リダイレクトで Cookie を読めるよう Path=/ が付くことを保証する
        run_test! do |response|
          # Rack 3 では Set-Cookie が複数あると配列になるため、まとめて1つの文字列で検証する
          set_cookie = Array(response.headers["Set-Cookie"]).join("\n")
          expect(set_cookie).to match(/refresh_token=/i)
          expect(set_cookie).to match(/path=\//i)
          # 役目を終えた signup_token は破棄する
          expect(set_cookie).to match(/signup_token=;/i)
          expect(UserIdentity.last.provider_uid).to eq("uid_123")
        end
      end

      response "401", "signup_token が無効" do
        let(:Cookie) { "signup_token=invalid_token" }
        let(:body) { { nickname: "コムさん", username: "komusan" } }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code: { type: :string, example: "UNAUTHORIZED" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end

      response "409", "登録済みユーザー（(provider, provider_uid) 重複）" do
        let(:Cookie) { "signup_token=#{signup_token}" }
        let(:body) { { nickname: "コムさん", username: "komusan" } }

        before { create(:user_identity, provider: "google", provider_uid: "uid_123") }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code: { type: :string, example: "ACCOUNT_ALREADY_EXISTS" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end

      response "409", "username 重複" do
        let(:Cookie) { "signup_token=#{signup_token}" }
        let(:body) { { nickname: "コムさん", username: "komusan" } }

        before { create(:user, username: "komusan") }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code: { type: :string, example: "USERNAME_TAKEN" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end

      response "422", "バリデーションエラー" do
        let(:Cookie) { "signup_token=#{signup_token}" }
        let(:body) { { nickname: "", username: "ab" } }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code: { type: :string, example: "UNPROCESSABLE_ENTITY" },
                message: { type: :string },
                details: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      field: { type: :string },
                      message: { type: :string }
                    }
                  }
                }
              }
            }
          }

        run_test!
      end
    end
  end

  path "/v1/users/username/check" do
    get "ユーザーネーム重複チェックAPI" do
      tags "ユーザー系"
      produces "application/json"

      parameter name: :value, in: :query, type: :string, required: true,
        description: "チェックする username（3〜40文字、小文字英数字と _ のみ、連続する _ は不可）"

      response "200", "使用可能" do
        let(:value) { "available_user" }

        schema type: :object,
          properties: {
            available: { type: :boolean, example: true }
          },
          required: [ "available" ]

        run_test!
      end

      response "200", "重複あり（使用不可）" do
        let(:value) { "komusan" }

        before { create(:user, username: "komusan") }

        schema type: :object,
          properties: {
            available: { type: :boolean, example: false }
          },
          required: [ "available" ]

        run_test!
      end

      response "400", "value パラメータがない" do
        let(:value) { nil }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code: { type: :string, example: "BAD_REQUEST" },
                message: { type: :string }
              },
              required: [ "code", "message" ]
            }
          }

        run_test!
      end
    end
  end

  path "/v1/users/{username}" do
    get "ユーザープロフィール取得API" do
      tags "ユーザー系"
      produces "application/json"

      parameter name: :username, in: :path, type: :string, required: true,
        description: "取得するユーザーの username"

      response "200", "プロフィール取得成功" do
        let(:target_user) { create(:user) }
        let(:username) { target_user.username }

        schema type: :object,
          properties: {
            username:        { type: :string, example: "komusan" },
            nickname:        { type: :string, example: "コムさん" },
            bio:             { type: :string, nullable: true, example: "エンジニアです" },
            books_count:     { type: :integer, example: 0 },
            links:           { type: :array, items: { type: :string }, example: [] }
          },
          required: %w[username nickname bio books_count links]

        run_test!
      end

      response "404", "ユーザーが存在しない" do
        let(:username) { "nonexistent_user" }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "NOT_FOUND" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end
    end
  end
end
