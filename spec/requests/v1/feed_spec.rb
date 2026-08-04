require "swagger_helper"

RSpec.describe "フィード系", type: :request do
  path "/v1/feed" do
    get "フィード取得API" do
      tags "フィード系"
      produces "application/json"

      parameter name: :Authorization, in: :header, type: :string, required: false,
        description: "アクセストークン。任意。省略時は全ユーザーの投稿を返す"
      parameter name: :cursor, in: :query, type: :string, required: false,
        description: "前回レスポンスの next_cursor。不正な値の場合は 422 を返す"
      parameter name: :limit, in: :query, type: :integer, required: false,
        description: "最大取得件数（デフォルト20・上限50）。0以下はデフォルト値、上限超はクランプ"

      feed_item_schema = {
        type: :object,
        properties: {
          id:         { type: :integer, example: 1 },
          content:    { type: :string, nullable: true, example: "とても良い本でした" },
          tags:       { type: :array, items: { type: :string }, example: [ "Architecture", "Go" ] },
          created_at: { type: :string, example: "2026-03-05T00:00:00Z" },
          book: {
            type: :object,
            properties: {
              isbn:          { type: :string, example: "9784873116068" },
              title:         { type: :string, example: "リーダブルコード" },
              authors:       { type: :array, items: { type: :string }, example: [ "Dustin Boswell" ] },
              thumbnail_url: { type: :string, nullable: true, example: nil }
            },
            required: %w[isbn title authors thumbnail_url]
          },
          user: {
            type: :object,
            properties: {
              username: { type: :string, example: "komusan" },
              nickname: { type: :string, example: "コムさん" }
            },
            required: %w[username nickname]
          }
        },
        required: %w[id content tags created_at book user]
      }

      success_schema = {
        type: :object,
        properties: {
          items: { type: :array, items: feed_item_schema },
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
      }

      error_schema = {
        type: :object,
        properties: {
          error: {
            type: :object,
            properties: {
              code:    { type: :string },
              message: { type: :string }
            },
            required: %w[code message]
          }
        }
      }

      response "200", "ログイン済み：フォロー中ユーザー + 自分の投稿を取得" do
        let(:user) { create(:user, username: "komusan") }
        let(:followee) { create(:user, username: "followee_user") }
        let(:non_followed) { create(:user, username: "non_followed") }
        let(:Authorization) { "Bearer valid_token" }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          create(:follow, follower: user, followee: followee)
          create(:user_book, user: user, content: "自分の投稿")
          create(:user_book, user: followee, content: "フォロー中の投稿")
          create(:user_book, user: non_followed, content: "フォローしていない人の投稿")
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          contents = data["items"].map { |item| item["content"] }
          expect(contents).to contain_exactly("自分の投稿", "フォロー中の投稿")
        end
      end

      response "200", "ログイン済み：フォロー0人 → 自分の投稿のみ" do
        let(:user) { create(:user) }
        let(:other) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          create(:user_book, user: user, content: "自分の投稿")
          create(:user_book, user: other, content: "他人の投稿")
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          contents = data["items"].map { |item| item["content"] }
          expect(contents).to eq([ "自分の投稿" ])
        end
      end

      response "200", "未ログイン：全ユーザーの投稿を取得" do
        let(:Authorization) { nil }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          user_a = create(:user)
          user_b = create(:user)
          create(:user_book, user: user_a, content: "Aの投稿")
          create(:user_book, user: user_b, content: "Bの投稿")
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(2)
        end
      end

      response "200", "cursor / limit を指定してページネーション" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:limit) { 1 }
        let(:cursor) { nil }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          create_list(:user_book, 3, user: user)
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(1)
          expect(data["pagination"]["has_next"]).to eq(true)
          expect(data["pagination"]["next_cursor"]).not_to be_nil
        end
      end

      response "200", "投稿が存在しない" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"]).to eq([])
          expect(data["pagination"]["has_next"]).to eq(false)
          expect(data["pagination"]["next_cursor"]).to be_nil
        end
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          allow(TokenIssuer).to receive(:decode).with("invalid_token").and_return(nil)
        end

        schema error_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("UNAUTHORIZED")
        end
      end

      response "422", "不正なカーソル値" do
        let(:Authorization) { nil }
        let(:cursor) { "invalid_cursor!!!" }
        let(:limit) { nil }

        schema error_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("VALIDATION_ERROR")
        end
      end
    end
  end
end
