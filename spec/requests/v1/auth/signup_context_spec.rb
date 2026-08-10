require "swagger_helper"

RSpec.describe "認証系", type: :request do
  path "/v1/auth/signup_context" do
    get "サインアップコンテキスト取得API" do
      tags "認証系"
      produces "application/json"

      parameter name: "Cookie", in: :header, type: :string, required: true,
        description: "`signup_token=<JWT>`（コールバックが発行した10分有効の Cookie）"

      response "200", "取得成功" do
        let(:identity) do
          Oauth::Identity.new(provider: "google", uid: "uid_123", email: "komu@example.com", name: "コムサン")
        end
        let(:Cookie) { "signup_token=#{TokenIssuer.issue_signup_token(identity)}" }

        schema type: :object,
          properties: {
            email:               { type: :string, example: "user@example.com" },
            nickname_suggestion: { type: :string, example: "コムサン" }
          },
          required: %w[email nickname_suggestion]

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["email"]).to eq("komu@example.com")
          expect(body["nickname_suggestion"]).to eq("コムサン")
        end
      end

      response "401", "signup_token が無効・期限切れ・purpose 不一致" do
        let(:Cookie) { "signup_token=invalid_token" }

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
