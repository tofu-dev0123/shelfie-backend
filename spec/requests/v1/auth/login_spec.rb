require "swagger_helper"

RSpec.describe "認証系", type: :request do
  path "/v1/auth/login" do
    post "ログインAPI" do
      tags "認証系"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]

      response "200", "ログイン成功" do
        let(:Authorization) { "Bearer valid_clerk_token" }
        let!(:user) { create(:user, clerk_user_id: "clerk_abc123") }

        before do
          allow(ClerkClient).to receive(:verify).and_return({
            clerk_user_id: "clerk_abc123",
            email: user.email
          })
        end

        schema type: :object,
          properties: {
            access_token: { type: :string, example: "eyJ..." }
          },
          required: [ "access_token" ]

        # Set-Cookie の Path=/ が明示されていることを保証する（SSR で全パスに Cookie を添付するため）
        run_test! do |response|
          expect(response.headers["Set-Cookie"]).to match(/refresh_token=/i)
          expect(response.headers["Set-Cookie"]).to match(/path=\//i)
        end
      end

      response "401", "Clerk JWT が無効" do
        let(:Authorization) { "Bearer invalid_token" }

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

      response "404", "ユーザーが存在しない" do
        let(:Authorization) { "Bearer valid_clerk_token" }

        before do
          allow(ClerkClient).to receive(:verify).and_return({
            clerk_user_id: "clerk_not_registered",
            email: "unknown@example.com"
          })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code: { type: :string, example: "NOT_FOUND" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end
    end
  end
end
