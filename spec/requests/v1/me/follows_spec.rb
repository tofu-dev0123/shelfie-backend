require "swagger_helper"

RSpec.describe "フォロー系API", type: :request do
  path "/v1/me/follows/{username}" do
    post "フォローAPI" do
      tags "フォロー系"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :username, in: :path, type: :string, required: true,
        description: "フォローするユーザーの username"

      let(:current_user) { create(:user) }

      response "201", "フォロー成功" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "フォローしました" }
          },
          required: %w[message]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to eq("フォローしました")
          expect(Follow.find_by(follower_id: current_user.id, followee_id: target_user.id)).to be_present
        end
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:username) { "komusan" }
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
        let(:username) { "komusan" }
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

      response "404", "ユーザーが存在しない" do
        let(:username) { "not_exists_user" }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
        end

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

      response "409", "既にフォロー済み" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
          create(:follow, follower: current_user, followee: target_user)
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "CONFLICT" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end

      response "422", "自分自身をフォローしようとした" do
        let(:username) { current_user.username }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "VALIDATION_ERROR" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end
    end

    delete "フォロー解除API" do
      tags "フォロー系"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :username, in: :path, type: :string, required: true,
        description: "フォロー解除するユーザーの username"

      let(:current_user) { create(:user) }

      response "200", "フォロー解除成功" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
          create(:follow, follower: current_user, followee: target_user)
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "フォローを解除しました" }
          },
          required: %w[message]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to eq("フォローを解除しました")
          expect(Follow.find_by(follower_id: current_user.id, followee_id: target_user.id)).to be_nil
        end
      end

      response "200", "フォロー解除成功（フォローしていない場合も200）" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "フォローを解除しました" }
          },
          required: %w[message]

        run_test!
      end

      response "200", "フォロー解除成功（ユーザーが存在しない場合も200）" do
        let(:username) { "not_exists_user" }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "フォローを解除しました" }
          },
          required: %w[message]

        run_test!
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:username) { "komusan" }
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

      response "422", "自分自身のフォローを解除しようとした" do
        let(:username) { current_user.username }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "VALIDATION_ERROR" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end
    end
  end
end
