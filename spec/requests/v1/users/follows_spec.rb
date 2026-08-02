require "swagger_helper"

RSpec.describe "フォロー系API（一覧）", type: :request do
  path "/v1/users/{username}/followers" do
    get "フォロワー一覧取得API" do
      tags "フォロー系"
      produces "application/json"

      parameter name: :username, in: :path, type: :string, required: true,
        description: "取得するユーザーの username"
      parameter name: :cursor, in: :query, type: :string, required: false,
        description: "前回レスポンスの next_cursor（省略時は先頭から）"
      parameter name: :limit, in: :query, type: :integer, required: false,
        description: "最大取得件数。上限は50で、超えた場合は50にクランプされる（デフォルト20）"

      response "200", "フォロワー一覧取得成功" do
        let(:target_user) { create(:user, username: "komusan", nickname: "コムさん") }
        let(:username) { target_user.username }

        before do
          follower = create(:user, username: "follower1", nickname: "フォロワー1")
          create(:follow, follower: follower, followee: target_user)
        end

        schema type: :object,
          properties: {
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  username: { type: :string, example: "follower1" },
                  nickname: { type: :string, example: "フォロワー1" }
                },
                required: %w[username nickname]
              }
            },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true, example: nil },
                has_next:    { type: :boolean, example: false }
              },
              required: %w[next_cursor has_next]
            }
          },
          required: %w[items pagination]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(1)
          expect(data["items"].first["username"]).to eq("follower1")
        end
      end

      response "200", "ユーザーが存在しない場合も空配列で200" do
        let(:username) { "not_exists_user" }

        schema type: :object,
          properties: {
            items:      { type: :array, items: {}, example: [] },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true, example: nil },
                has_next:    { type: :boolean, example: false }
              },
              required: %w[next_cursor has_next]
            }
          },
          required: %w[items pagination]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"]).to eq([])
          expect(data["pagination"]["has_next"]).to eq(false)
        end
      end

      response "200", "フォロワーが0件の場合も空配列で200" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }

        schema type: :object,
          properties: {
            items:      { type: :array, items: {}, example: [] },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true },
                has_next:    { type: :boolean }
              },
              required: %w[next_cursor has_next]
            }
          },
          required: %w[items pagination]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"]).to eq([])
          expect(data["pagination"]["has_next"]).to eq(false)
        end
      end

      response "200", "limit が50超のときクランプされる" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }
        let(:limit) { 100 }

        before do
          51.times do
            follower = create(:user)
            create(:follow, follower: follower, followee: target_user)
          end
        end

        schema type: :object,
          properties: {
            items:      { type: :array, items: {} },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true },
                has_next:    { type: :boolean }
              },
              required: %w[next_cursor has_next]
            }
          },
          required: %w[items pagination]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(50)
          expect(data["pagination"]["has_next"]).to eq(true)
        end
      end

      response "200", "cursor を指定してページネーション" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }
        let(:limit) { 1 }

        before do
          follower1 = create(:user, username: "follower1")
          follower2 = create(:user, username: "follower2")
          create(:follow, follower: follower1, followee: target_user)
          create(:follow, follower: follower2, followee: target_user)
        end

        schema type: :object,
          properties: {
            items:      { type: :array },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true },
                has_next:    { type: :boolean }
              }
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(1)
          expect(data["pagination"]["has_next"]).to eq(true)
          expect(data["pagination"]["next_cursor"]).not_to be_nil
        end
      end
    end
  end

  path "/v1/users/{username}/following" do
    get "フォロー中一覧取得API" do
      tags "フォロー系"
      produces "application/json"

      parameter name: :username, in: :path, type: :string, required: true,
        description: "取得するユーザーの username"
      parameter name: :cursor, in: :query, type: :string, required: false,
        description: "前回レスポンスの next_cursor（省略時は先頭から）"
      parameter name: :limit, in: :query, type: :integer, required: false,
        description: "最大取得件数。上限は50で、超えた場合は50にクランプされる（デフォルト20）"

      response "200", "フォロー中一覧取得成功" do
        let(:target_user) { create(:user, username: "komusan", nickname: "コムさん") }
        let(:username) { target_user.username }

        before do
          followee = create(:user, username: "followee1", nickname: "フォロー中1")
          create(:follow, follower: target_user, followee: followee)
        end

        schema type: :object,
          properties: {
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  username: { type: :string, example: "followee1" },
                  nickname: { type: :string, example: "フォロー中1" }
                },
                required: %w[username nickname]
              }
            },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true, example: nil },
                has_next:    { type: :boolean, example: false }
              },
              required: %w[next_cursor has_next]
            }
          },
          required: %w[items pagination]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(1)
          expect(data["items"].first["username"]).to eq("followee1")
        end
      end

      response "200", "ユーザーが存在しない場合も空配列で200" do
        let(:username) { "not_exists_user" }

        schema type: :object,
          properties: {
            items:      { type: :array, items: {}, example: [] },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true, example: nil },
                has_next:    { type: :boolean, example: false }
              },
              required: %w[next_cursor has_next]
            }
          },
          required: %w[items pagination]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"]).to eq([])
          expect(data["pagination"]["has_next"]).to eq(false)
        end
      end

      response "200", "フォロー中が0件の場合も空配列で200" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }

        schema type: :object,
          properties: {
            items:      { type: :array, items: {}, example: [] },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true },
                has_next:    { type: :boolean }
              },
              required: %w[next_cursor has_next]
            }
          },
          required: %w[items pagination]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"]).to eq([])
          expect(data["pagination"]["has_next"]).to eq(false)
        end
      end

      response "200", "limit が50超のときクランプされる" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }
        let(:limit) { 100 }

        before do
          51.times do
            followee = create(:user)
            create(:follow, follower: target_user, followee: followee)
          end
        end

        schema type: :object,
          properties: {
            items:      { type: :array, items: {} },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true },
                has_next:    { type: :boolean }
              },
              required: %w[next_cursor has_next]
            }
          },
          required: %w[items pagination]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(50)
          expect(data["pagination"]["has_next"]).to eq(true)
        end
      end

      response "200", "cursor を指定してページネーション" do
        let(:target_user) { create(:user, username: "komusan") }
        let(:username) { target_user.username }
        let(:limit) { 1 }

        before do
          followee1 = create(:user, username: "followee1")
          followee2 = create(:user, username: "followee2")
          create(:follow, follower: target_user, followee: followee1)
          create(:follow, follower: target_user, followee: followee2)
        end

        schema type: :object,
          properties: {
            items:      { type: :array },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true },
                has_next:    { type: :boolean }
              }
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(1)
          expect(data["pagination"]["has_next"]).to eq(true)
          expect(data["pagination"]["next_cursor"]).not_to be_nil
        end
      end
    end
  end
end
