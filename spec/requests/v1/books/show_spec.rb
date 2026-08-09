require "swagger_helper"

RSpec.describe "書籍系", type: :request do
  let(:current_user) { create(:user) }
  let(:Authorization) { "Bearer valid_token" }

  before do
    allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => current_user.id })
  end

  path "/v1/books/{isbn}" do
    get "書籍取得API" do
      tags "書籍系"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :isbn, in: :path, type: :string, required: true,
        description: "書籍の ISBN-13（13桁の数字）"

      let(:rakuten_books_response) do
        {
          count: 1,
          page: 1,
          pageCount: 1,
          Items: [
            {
              isbn: "9784873118079",
              title: "リーダブルコード",
              author: "Dustin Boswell／Trevor Foucher",
              largeImageUrl: "https://example.com/thumbnail.jpg"
            }
          ]
        }.to_json
      end

      response "200", "書籍取得成功" do
        let(:isbn) { "9784873118079" }

        before do
          stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
            .to_return(status: 200, body: rakuten_books_response, headers: { "Content-Type" => "application/json" })
        end

        schema type: :object,
          properties: {
            isbn:          { type: :string, example: "9784873118079" },
            title:         { type: :string, example: "リーダブルコード" },
            authors:       { type: :array, items: { type: :string }, example: [ "Dustin Boswell", "Trevor Foucher" ] },
            thumbnail_url: { type: :string, nullable: true, example: "https://example.com/thumbnail.jpg" }
          },
          required: %w[isbn title authors thumbnail_url]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["isbn"]).to eq("9784873118079")
          expect(data["title"]).to eq("リーダブルコード")
          expect(data["authors"]).to eq([ "Dustin Boswell", "Trevor Foucher" ])
          expect(data["thumbnail_url"]).to eq("https://example.com/thumbnail.jpg")
        end
      end

      response "401", "アクセストークンが無効" do
        let(:isbn) { "9784873118079" }
        let(:Authorization) { "Bearer invalid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("invalid_token", purpose: "access").and_return(nil)
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

      response "404", "楽天 Books API に書籍が存在しない" do
        let(:isbn) { "9784000000001" }

        before do
          stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
            .to_return(status: 200, body: { count: 0, page: 1, pageCount: 0, Items: [] }.to_json, headers: { "Content-Type" => "application/json" })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "NOT_FOUND" },
                message: { type: :string }
              },
              required: %w[code message]
            }
          }

        run_test!
      end

      response "404", "isbn の形式が不正（ルートにマッチしない）" do
        let(:isbn) { "invalid-isbn" }

        run_test!
      end

      response "503", "楽天 Books API エラー" do
        let(:isbn) { "9784873118079" }

        before do
          stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
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
