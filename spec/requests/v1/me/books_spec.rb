require "swagger_helper"

RSpec.describe "本棚API", type: :request do
  path "/v1/me/books" do
    post "本棚追加API" do
      tags "本棚系"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          isbn:           { type: :string, example: "9784873116068" },
          content:        { type: :string, example: "とても良い本でした #Go #アーキテクチャ" }
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
        let(:body) { { isbn: "9784873116068", content: "良い本 #Go" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
          stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
            .to_return(status: 200, body: rakuten_response.to_json, headers: { "Content-Type" => "application/json" })
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "登録が完了しました" }
          },
          required: %w[message]

        run_test! do
          user_book = user.user_books.last
          expect(user_book.content).to eq("良い本 #Go")
        end
      end

      response "201", "登録成功（DBに書籍あり→楽天API不要）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { isbn: "9784873116068" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
          create(:book, isbn: "9784873116068")
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "登録が完了しました" }
          },
          required: %w[message]

        run_test!
      end

      response "201", "本文中の `#` はただのテキストとして保持される" do
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { isbn: "9784873116068", content: "#Go #アーキテクチャ 良かった" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
          create(:book, isbn: "9784873116068")
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "登録が完了しました" }
          },
          required: %w[message]

        run_test! do
          user_book = user.user_books.last
          expect(user_book.content).to eq("#Go #アーキテクチャ 良かった")
        end
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:body) { { isbn: "9784873116068" } }

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
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
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
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
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
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
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
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
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

  path "/v1/me/books/{isbn}" do
    put "本棚投稿更新API" do
      tags "本棚系"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :isbn, in: :path, type: :string, required: true,
        description: "書籍の ISBN-13"
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          content:        { type: :string, example: "改めて読み直したら更に良かったです #Go #アーキテクチャ" }
        },
        required: %w[content]
      }

      let(:user) { create(:user) }
      let(:book) { create(:book) }

      response "200", "更新成功（本文中の `#` はただのテキストとして保持される）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { book.isbn }
        let(:body) { { content: "改めて読み直したら更に良かったです #Go" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
          create(:user_book, user: user, book: book)
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "更新が完了しました" }
          },
          required: %w[message]

        run_test! do
          user_book = UserBook.find_by!(user: user, book: book)
          expect(user_book.content).to eq("改めて読み直したら更に良かったです #Go")
        end
      end

      response "200", "本文を空文字で置き換えられる" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { book.isbn }
        let(:body) { { content: "" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
          create(:user_book, user: user, book: book, content: "以前の本文 #Go")
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "更新が完了しました" }
          },
          required: %w[message]

        run_test! do
          user_book = UserBook.find_by!(user: user, book: book)
          expect(user_book.content).to eq("")
        end
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:isbn) { book.isbn }
        let(:body) { { content: "" } }

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
              }
            }
          }

        run_test!
      end

      response "401", "アクセストークンなし" do
        let(:Authorization) { nil }
        let(:isbn) { book.isbn }
        let(:body) { { content: "" } }

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

      response "404", "書籍または投稿が存在しない" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784000000001" }
        let(:body) { { content: "" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
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

      response "422", "content が1000文字超" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { book.isbn }
        let(:body) { { content: "a" * 1001 } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
          create(:user_book, user: user, book: book)
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

    delete "本棚投稿削除API" do
      tags "本棚系"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :isbn, in: :path, type: :string, required: true,
        description: "書籍の ISBN-13"

      let(:user) { create(:user) }
      let(:book) { create(:book) }

      response "200", "正常削除" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { book.isbn }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
          create(:user_book, user: user, book: book)
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "削除が完了しました" }
          },
          required: %w[message]

        run_test!
      end

      response "200", "冪等性：user_books が存在しない" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { book.isbn }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "削除が完了しました" }
          },
          required: %w[message]

        run_test!
      end

      response "200", "冪等性：book 自体が存在しない isbn" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784000000001" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "削除が完了しました" }
          },
          required: %w[message]

        run_test!
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:isbn) { book.isbn }

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
              }
            }
          }

        run_test!
      end

      response "401", "アクセストークンなし" do
        let(:Authorization) { nil }
        let(:isbn) { book.isbn }

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

      response "422", "isbn が13桁の数字でない" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "invalid" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token", purpose: "access").and_return({ "user_id" => user.id })
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
