require "swagger_helper"

RSpec.describe "書籍系", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { "Bearer valid_token" }

  before do
    allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => current_user.id })
  end

  path "/v1/books/search" do
    get "書籍検索API" do
      tags "書籍系"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :q, in: :query, type: :string, required: true,
        description: "検索キーワード（空白トリム後1文字以上・100文字以内）"
      parameter name: :cursor, in: :query, type: :string, required: false,
        description: "前回レスポンスの next_cursor（省略時は先頭から）"

      let(:google_books_response) do
        {
          totalItems: 100,
          items: [
            {
              id: "abc123",
              volumeInfo: {
                title: "リーダブルコード",
                authors: [ "Dustin Boswell", "Trevor Foucher" ],
                imageLinks: { thumbnail: "https://example.com/thumbnail.jpg" }
              }
            }
          ]
        }.to_json
      end

      response "200", "検索結果あり" do
        let(:q) { "Rails" }

        before do
          stub_request(:get, /googleapis.com\/books\/v1\/volumes/)
            .to_return(status: 200, body: google_books_response, headers: { "Content-Type" => "application/json" })
        end

        schema type: :object,
          properties: {
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  google_books_id: { type: :string, example: "abc123" },
                  title:           { type: :string, example: "リーダブルコード" },
                  authors:         { type: :array, items: { type: :string }, example: [ "Dustin Boswell" ] },
                  thumbnail_url:   { type: :string, nullable: true, example: "https://..." }
                },
                required: %w[google_books_id title authors thumbnail_url]
              }
            },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true, example: "eyJzdGFydEluZGV4IjoxMH0=" },
                has_next:    { type: :boolean, example: true }
              },
              required: %w[next_cursor has_next]
            }
          },
          required: %w[items pagination]

        run_test!
      end

      response "200", "検索結果 0件" do
        let(:q) { "存在しない書籍xyzxyz" }

        before do
          stub_request(:get, /googleapis.com\/books\/v1\/volumes/)
            .to_return(status: 200, body: { totalItems: 0, items: [] }.to_json, headers: { "Content-Type" => "application/json" })
        end

        schema type: :object,
          properties: {
            items:      { type: :array, items: {}, example: [] },
            pagination: {
              type: :object,
              properties: {
                next_cursor: { type: :string, nullable: true, example: nil },
                has_next:    { type: :boolean, example: false }
              }
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"]).to eq([])
          expect(data["pagination"]["has_next"]).to eq(false)
        end
      end

      response "401", "アクセストークンが無効" do
        let(:q) { "Rails" }
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
              },
              required: %w[code message]
            }
          }

        run_test!
      end

      response "422", "q が空" do
        let(:q) { "" }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "VALIDATION_ERROR" },
                message: { type: :string }
              },
              required: %w[code message]
            }
          }

        run_test!
      end

      response "422", "q が空白のみ" do
        let(:q) { "   " }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "VALIDATION_ERROR" },
                message: { type: :string }
              },
              required: %w[code message]
            }
          }

        run_test!
      end

      response "422", "q が100文字超" do
        let(:q) { "a" * 101 }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "VALIDATION_ERROR" },
                message: { type: :string }
              },
              required: %w[code message]
            }
          }

        run_test!
      end

      response "422", "cursor のデコード失敗" do
        let(:q) { "Rails" }
        let(:cursor) { "invalid_cursor!!!" }

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "VALIDATION_ERROR" },
                message: { type: :string }
              },
              required: %w[code message]
            }
          }

        run_test!
      end

      response "503", "Google Books API エラー" do
        let(:q) { "Rails" }

        before do
          stub_request(:get, /googleapis.com\/books\/v1\/volumes/)
            .to_return(status: 500)
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "EXTERNAL_API_ERROR" },
                message: { type: :string }
              },
              required: %w[code message]
            }
          }

        run_test!
      end
    end
  end
end
