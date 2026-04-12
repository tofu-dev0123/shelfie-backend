require "swagger_helper"

RSpec.describe "アクセストークン再発行API", type: :request do
  path "/v1/auth/refresh" do
    post "アクセストークン再発行API" do
      tags "認証系"
      produces "application/json"

      response "200", "再発行成功（リフレッシュトークンのローテーションなし）" do
        let(:user) { create(:user) }
        let!(:refresh_token_record) do
          create(:refresh_token, user: user, token: "valid_refresh_token",
                                 expires_at: 20.days.from_now)
        end

        before do
          cookies[:refresh_token] = "valid_refresh_token"
        end

        schema type: :object,
          properties: {
            access_token: { type: :string, example: "eyJ..." }
          },
          required: [ "access_token" ]

        run_test!
      end

      response "200", "再発行成功（リフレッシュトークンのローテーションあり）" do
        let(:user) { create(:user) }
        let!(:refresh_token_record) do
          create(:refresh_token, user: user, token: "expiring_refresh_token",
                                 expires_at: 10.days.from_now)
        end

        before do
          cookies[:refresh_token] = "expiring_refresh_token"
        end

        schema type: :object,
          properties: {
            access_token: { type: :string, example: "eyJ..." }
          },
          required: [ "access_token" ]

        run_test!
      end

      response "401", "Cookie なし" do
        # Cookie をセットしない

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

      response "401", "リフレッシュトークンが DB に存在しない" do
        before do
          cookies[:refresh_token] = "nonexistent_token"
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

      response "401", "リフレッシュトークンが期限切れ" do
        let(:user) { create(:user) }
        let!(:refresh_token_record) do
          create(:refresh_token, user: user, token: "expired_refresh_token",
                                 expires_at: 1.day.ago)
        end

        before do
          cookies[:refresh_token] = "expired_refresh_token"
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
    end
  end
end
