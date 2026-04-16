require "swagger_helper"

RSpec.describe "読みたい系API", type: :request do
  path "/v1/me/want_to_reads" do
    get "読みたいリストを取得する" do
      tags "読みたい系"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :cursor, in: :query, type: :string, required: false,
        description: "前回レスポンスの next_cursor"
      parameter name: :limit, in: :query, type: :integer, required: false,
        description: "最大取得件数（デフォルト20・上限50）"

      let(:user) { create(:user) }

      response "200", "読みたいリストを取得（データあり）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          book = create(:book, isbn: "9784873116068", title: "リーダブルコード", authors: [ "Dustin Boswell" ], thumbnail_url: "https://example.com/thumb.jpg")
          create(:want_to_read, user: user, book: book)
        end

        schema type: :object,
          properties: {
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  isbn:          { type: :string, example: "9784873116068" },
                  title:         { type: :string, example: "リーダブルコード" },
                  authors:       { type: :array, items: { type: :string }, example: [ "Dustin Boswell" ] },
                  thumbnail_url: { type: :string, nullable: true, example: "https://example.com/thumb.jpg" }
                },
                required: %w[isbn title authors thumbnail_url]
              }
            },
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

        run_test!
      end

      response "200", "読みたいリストを取得（データなし）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:cursor) { nil }
        let(:limit) { nil }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            items: { type: :array, items: {}, example: [] },
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

      response "200", "cursor / limit を指定してページネーション" do
        let(:Authorization) { "Bearer valid_token" }
        let(:limit) { 1 }
        let(:cursor) { nil }

        let!(:book1) { create(:book) }
        let!(:book2) { create(:book) }
        let!(:wtr1)  { create(:want_to_read, user: user, book: book1) }
        let!(:wtr2)  { create(:want_to_read, user: user, book: book2) }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            items: { type: :array },
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

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:cursor) { nil }
        let(:limit) { nil }

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
        let(:Authorization) { nil }
        let(:cursor) { nil }
        let(:limit) { nil }

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

      response "422", "cursor が無効な値" do
        let(:Authorization) { "Bearer valid_token" }
        let(:cursor) { "invalid_cursor" }
        let(:limit) { nil }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
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
