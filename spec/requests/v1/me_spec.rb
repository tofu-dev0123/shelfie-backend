require "swagger_helper"

RSpec.describe "マイページ系", type: :request do
  path "/v1/me" do
    get "マイプロフィール取得API" do
      tags "マイページ系"
      produces "application/json"
      security [ Bearer: [] ]

      response "200", "プロフィール取得成功" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            id:              { type: :integer, example: 1 },
            username:        { type: :string, example: "komusan" },
            nickname:        { type: :string, example: "コムさん" },
            bio:             { type: :string, nullable: true, example: "エンジニアです" },
            avatar_url:      { type: :string, nullable: true, example: nil },
            followers_count: { type: :integer, example: 0 },
            following_count: { type: :integer, example: 0 },
            books_count:     { type: :integer, example: 0 },
            links:           { type: :array, items: { type: :string }, example: [] }
          },
          required: %w[id username nickname bio avatar_url followers_count following_count books_count links]

        run_test!
      end

      response "401", "アクセストークンが無効・期限切れ" do
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

      response "401", "アクセストークンなし" do
        # Authorization ヘッダーを送らないことで 401 を確認する
        let(:Authorization) { nil }

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
