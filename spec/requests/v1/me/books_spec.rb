require "swagger_helper"

RSpec.describe "本棚追加API", type: :request do
  path "/v1/me/books" do
    post "本棚に書籍を追加する" do
      tags "マイページ系"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          isbn:           { type: :string, example: "9784873116068" },
          content:        { type: :string, example: "とても良い本でした" },
          tags:           { type: :array, items: { type: :string }, example: [ "Go", "アーキテクチャ" ] },
          purchase_links: { type: :array, items: { type: :string }, example: [ "https://www.amazon.co.jp/..." ] }
        },
        required: [ "isbn" ]
      }

      let(:user) { create(:user) }
      let(:book_item) do
        {
          isbn: "9784873116068",
          title: "プログラミングGo",
          author: "Alan A. A. Donovan／Brian W. Kernighan",
          largeImageUrl: "https://thumbnail.image.rakuten.co.jp/test.jpg",
          salesDate: "2016年06月"
        }
      end
      let(:rakuten_response) { { Items: [ book_item ], count: 1 } }

      response "201", "登録成功（DBに書籍なし→楽天API取得）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { isbn: "9784873116068", content: "良い本", tags: [ "Go" ], purchase_links: [ "https://example.com" ] } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          create(:tag, name: "Go")
          stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
            .to_return(status: 200, body: rakuten_response.to_json, headers: { "Content-Type" => "application/json" })
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "登録が完了しました" }
          },
          required: %w[message]

        run_test!
      end

      response "201", "登録成功（DBに書籍あり→楽天API不要）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { isbn: "9784873116068" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          create(:book, isbn: "9784873116068")
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "登録が完了しました" }
          },
          required: %w[message]

        run_test!
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:body) { { isbn: "9784873116068" } }

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
        let(:body) { { isbn: "9784873116068" } }

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

      response "404", "楽天書籍APIに書籍が存在しない" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { isbn: "9784873116068" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
            .to_return(status: 200, body: { Items: [], count: 0 }.to_json, headers: { "Content-Type" => "application/json" })
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

      response "409", "すでに同じ書籍を登録済み" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { isbn: "9784873116068" } }
        let!(:existing_book) { create(:book, isbn: "9784873116068") }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          create(:user_book, user: user, book: existing_book)
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

      response "422", "ISBNが13桁の数字でない" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { isbn: "invalid" } }

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

      response "422", "存在しないタグが含まれている" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { isbn: "9784873116068", tags: [ "存在しないタグ" ] } }
        let!(:book) { create(:book, isbn: "9784873116068") }

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

      response "503", "楽天書籍APIがエラーを返した" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { isbn: "9784873116068" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
            .to_raise(ExternalApiError)
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "EXTERNAL_API_ERROR" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end
    end
  end
end
