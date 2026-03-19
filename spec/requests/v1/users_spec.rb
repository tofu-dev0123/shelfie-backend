require "swagger_helper"

RSpec.describe "ユーザー系", type: :request do
  path "/v1/users" do
    post "ユーザー登録API" do
      tags "ユーザー系"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          nickname: { type: :string, example: "コムさん" },
          username: { type: :string, example: "komusan" }
        },
        required: [ "nickname", "username" ]
      }

      response "201", "ユーザー作成成功" do
        let(:Authorization) { "Bearer valid_clerk_token" }
        let(:body) { { nickname: "コムさん", username: "komusan" } }

        before do
          allow(ClerkClient).to receive(:verify).and_return({
            clerk_user_id: "clerk_abc123",
            email: "komu@example.com"
          })
        end

        schema type: :object,
          properties: {
            access_token: { type: :string, example: "eyJ..." }
          },
          required: [ "access_token" ]

        run_test!
      end

      response "401", "Clerk JWT が無効" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:body) { { nickname: "コムさん", username: "komusan" } }

        before do
          allow(ClerkClient).to receive(:verify).and_raise(ClerkClient::UnauthorizedError)
        end

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

      response "409", "登録済みユーザー（clerk_user_id 重複）" do
        let(:Authorization) { "Bearer valid_clerk_token" }
        let(:body) { { nickname: "コムさん", username: "komusan" } }

        before do
          allow(ClerkClient).to receive(:verify).and_return({
            clerk_user_id: "clerk_abc123",
            email: "komu@example.com"
          })
          create(:user, clerk_user_id: "clerk_abc123", email: "komu@example.com", username: "komusan")
        end

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
        let(:Authorization) { "Bearer valid_clerk_token" }
        let(:body) { { nickname: "コムさん", username: "komusan" } }

        before do
          allow(ClerkClient).to receive(:verify).and_return({
            clerk_user_id: "clerk_new123",
            email: "new@example.com"
          })
          create(:user, username: "komusan")
        end

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
        let(:Authorization) { "Bearer valid_clerk_token" }
        let(:body) { { nickname: "", username: "ab" } }

        before do
          allow(ClerkClient).to receive(:verify).and_return({
            clerk_user_id: "clerk_abc123",
            email: "komu@example.com"
          })
        end

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

      response "422", "形式不正" do
        let(:value) { "INVALID__name" }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code: { type: :string, example: "VALIDATION_ERROR" },
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
      security [ { Bearer: [] }, {} ]

      parameter name: :username, in: :path, type: :string, required: true,
        description: "取得するユーザーの username"

      response "200", "プロフィール取得成功（未認証時）" do
        let(:target_user) { create(:user) }
        let(:username) { target_user.username }

        schema type: :object,
          properties: {
            username:        { type: :string, example: "komusan" },
            nickname:        { type: :string, example: "コムさん" },
            bio:             { type: :string, nullable: true, example: "エンジニアです" },
            avatar_url:      { type: :string, nullable: true, example: nil },
            followers_count: { type: :integer, example: 0 },
            following_count: { type: :integer, example: 0 },
            books_count:     { type: :integer, example: 0 },
            links:           { type: :array, items: { type: :string }, example: [] }
          },
          required: %w[username nickname bio avatar_url followers_count following_count books_count links]

        run_test!
      end

      response "200", "プロフィール取得成功（認証済み時・他ユーザー）" do
        let(:target_user)   { create(:user) }
        let(:current_user)  { create(:user) }
        let(:username)      { target_user.username }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
        end

        schema type: :object,
          properties: {
            username:        { type: :string },
            nickname:        { type: :string },
            bio:             { type: :string, nullable: true },
            avatar_url:      { type: :string, nullable: true },
            followers_count: { type: :integer },
            following_count: { type: :integer },
            books_count:     { type: :integer },
            links:           { type: :array, items: { type: :string } },
            is_following:    { type: :boolean, example: false }
          },
          required: %w[username nickname bio avatar_url followers_count following_count books_count links is_following]

        run_test!
      end

      response "200", "プロフィール取得成功（自分自身・is_following が false）" do
        let(:current_user)  { create(:user) }
        let(:username)      { current_user.username }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
        end

        schema type: :object,
          properties: {
            is_following: { type: :boolean, example: false }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["is_following"]).to eq(false)
        end
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

      response "401", "アクセストークンが不正" do
        let(:target_user)   { create(:user) }
        let(:username)      { target_user.username }
        let(:Authorization) { "Bearer invalid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("invalid_token").and_return(nil)
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "UNAUTHORIZED" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end
    end
  end
end
