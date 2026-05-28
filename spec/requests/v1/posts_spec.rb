require "swagger_helper"

RSpec.describe "投稿系", type: :request do
  path "/v1/posts/search" do
    get "投稿検索API" do
      tags "投稿系"
      produces "application/json"

      parameter name: :Authorization, in: :header, type: :string, required: false,
        description: "アクセストークン。任意。指定時は is_in_my_want_to_read が boolean になる（未指定時は null）"
      parameter name: :q, in: :query, type: :string, required: false,
        description: "投稿本文の部分一致検索クエリ（空白トリム後1文字以上・100文字以内）。tag と同時指定は不可"
      parameter name: :tag, in: :query, type: :string, required: false,
        description: "タグ名による完全一致検索（50文字以内）。q と同時指定は不可"
      parameter name: :cursor, in: :query, type: :string, required: false,
        description: "前回レスポンスの next_cursor（省略時は先頭から）"
      parameter name: :limit, in: :query, type: :integer, required: false,
        description: "最大取得件数（デフォルト20・上限50）。0以下はデフォルト値、上限超はクランプ"

      feed_item_schema = {
        type: :object,
        properties: {
          id:         { type: :integer, example: 1 },
          content:    { type: :string, nullable: true, example: "とても良い本でした #Go" },
          tags:       { type: :array, items: { type: :string }, example: [ "Go" ] },
          created_at: { type: :string, example: "2026-03-05T00:00:00Z" },
          book: {
            type: :object,
            properties: {
              isbn:                  { type: :string, example: "9784873118079" },
              title:                 { type: :string, example: "リーダブルコード" },
              authors:               { type: :array, items: { type: :string }, example: [ "Dustin Boswell" ] },
              thumbnail_url:         { type: :string, nullable: true, example: nil },
              is_in_my_want_to_read: { type: :boolean, nullable: true, example: nil }
            },
            required: %w[isbn title authors thumbnail_url is_in_my_want_to_read]
          },
          user: {
            type: :object,
            properties: {
              username:   { type: :string, example: "komusan" },
              nickname:   { type: :string, example: "コムさん" },
              avatar_url: { type: :string, nullable: true, example: nil }
            },
            required: %w[username nickname avatar_url]
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

      response "200", "本文検索：部分一致した投稿を取得" do
        let(:Authorization) { nil }
        let(:q) { "Ruby" }
        let(:tag) { nil }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          create(:user_book, content: "Ruby on Rails の本でした")
          create(:user_book, content: "Go の本でした")
          create(:user_book, content: "ruby は良い言語")
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          contents = data["items"].map { |item| item["content"] }
          expect(contents).to contain_exactly("Ruby on Rails の本でした", "ruby は良い言語")
        end
      end

      response "200", "タグ検索：完全一致した投稿を取得" do
        let(:Authorization) { nil }
        let(:q) { nil }
        let(:tag) { "Go" }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          go_tag    = create(:tag, name: "Go")
          ruby_tag  = create(:tag, name: "Ruby")
          golang_tag = create(:tag, name: "Golang")

          ub_go     = create(:user_book, content: "Go の本")
          ub_ruby   = create(:user_book, content: "Ruby の本")
          ub_golang = create(:user_book, content: "Golang の本")

          create(:user_book_tag, user_book: ub_go,     tag: go_tag)
          create(:user_book_tag, user_book: ub_ruby,   tag: ruby_tag)
          create(:user_book_tag, user_book: ub_golang, tag: golang_tag)
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          contents = data["items"].map { |item| item["content"] }
          expect(contents).to eq([ "Go の本" ])
        end
      end

      response "200", "ログイン済み：読みたい登録済み書籍は is_in_my_want_to_read=true" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:q) { "テスト" }
        let(:tag) { nil }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          book = create(:book)
          create(:user_book, user: user, book: book, content: "テスト投稿")
          create(:want_to_read, user: user, book: book)
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].first["book"]["is_in_my_want_to_read"]).to eq(true)
        end
      end

      response "200", "未ログイン：is_in_my_want_to_read は null" do
        let(:Authorization) { nil }
        let(:q) { "テスト" }
        let(:tag) { nil }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          create(:user_book, content: "テスト投稿")
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].first["book"]["is_in_my_want_to_read"]).to be_nil
        end
      end

      response "200", "cursor / limit を指定してページネーション" do
        let(:Authorization) { nil }
        let(:q) { "テスト" }
        let(:tag) { nil }
        let(:limit) { 1 }
        let(:cursor) { nil }

        before do
          create_list(:user_book, 3, content: "テスト投稿")
        end

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].size).to eq(1)
          expect(data["pagination"]["has_next"]).to eq(true)
          expect(data["pagination"]["next_cursor"]).not_to be_nil
        end
      end

      response "200", "該当する投稿が0件" do
        let(:Authorization) { nil }
        let(:q) { "存在しないキーワード" }
        let(:tag) { nil }
        let(:cursor) { nil }
        let(:limit) { nil }

        schema success_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"]).to eq([])
          expect(data["pagination"]["has_next"]).to eq(false)
          expect(data["pagination"]["next_cursor"]).to be_nil
        end
      end

      response "422", "q と tag を同時指定" do
        let(:Authorization) { nil }
        let(:q) { "Ruby" }
        let(:tag) { "Go" }
        let(:cursor) { nil }
        let(:limit) { nil }

        schema error_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("VALIDATION_ERROR")
        end
      end

      response "422", "q と tag のどちらも未指定" do
        let(:Authorization) { nil }
        let(:q) { nil }
        let(:tag) { nil }
        let(:cursor) { nil }
        let(:limit) { nil }

        schema error_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("VALIDATION_ERROR")
        end
      end

      response "422", "q が長すぎる" do
        let(:Authorization) { nil }
        let(:q) { "a" * 101 }
        let(:tag) { nil }
        let(:cursor) { nil }
        let(:limit) { nil }

        schema error_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("VALIDATION_ERROR")
        end
      end

      response "422", "tag が長すぎる" do
        let(:Authorization) { nil }
        let(:q) { nil }
        let(:tag) { "a" * 51 }
        let(:cursor) { nil }
        let(:limit) { nil }

        schema error_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("VALIDATION_ERROR")
        end
      end

      response "422", "不正なカーソル値" do
        let(:Authorization) { nil }
        let(:q) { "テスト" }
        let(:tag) { nil }
        let(:cursor) { "invalid_cursor!!!" }
        let(:limit) { nil }

        schema error_schema

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["code"]).to eq("VALIDATION_ERROR")
        end
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:q) { "テスト" }
        let(:tag) { nil }
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
    end
  end
end
