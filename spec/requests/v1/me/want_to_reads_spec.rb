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
                  isbn:                  { type: :string, example: "9784873116068" },
                  title:                 { type: :string, example: "リーダブルコード" },
                  authors:               { type: :array, items: { type: :string }, example: [ "Dustin Boswell" ] },
                  thumbnail_url:         { type: :string, nullable: true, example: "https://example.com/thumb.jpg" },
                  is_in_my_want_to_read: { type: :boolean, example: true, description: "自分の読みたいリスト由来のため常に true" }
                },
                required: %w[isbn title authors thumbnail_url is_in_my_want_to_read]
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

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].first["is_in_my_want_to_read"]).to eq(true)
        end
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

  path "/v1/me/want_to_reads/{isbn}" do
    post "読みたいリストに書籍を追加する" do
      tags "読みたい系"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :isbn, in: :path, type: :string, required: true,
        description: "ISBN-13形式（13桁の数字のみ）"

      let(:user) { create(:user) }
      let(:book_item) do
        {
          isbn:          "9784873116068",
          title:         "リーダブルコード",
          author:        "Dustin Boswell／Trevor Foucher",
          largeImageUrl: "https://thumbnail.image.rakuten.co.jp/test.jpg"
        }
      end
      let(:rakuten_response) { { Items: [ book_item ], count: 1 } }

      response "201", "追加成功（DBに書籍あり）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784873116068" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          create(:book, isbn: "9784873116068")
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "読みたいリストに追加しました" }
          },
          required: %w[message]

        run_test!
      end

      response "201", "追加成功（DBに書籍なし→楽天API取得）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784873116068" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          stub_request(:get, /openapi\.rakuten\.co\.jp\/services\/api\/BooksBook/)
            .to_return(status: 200, body: rakuten_response.to_json, headers: { "Content-Type" => "application/json" })
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "読みたいリストに追加しました" }
          },
          required: %w[message]

        run_test!
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:isbn) { "9784873116068" }

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

      response "404", "楽天書籍APIに書籍が存在しない" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784873116999" }

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

      response "409", "既に読みたいリストに追加済み" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784873116068" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          book = create(:book, isbn: "9784873116068")
          create(:want_to_read, user: user, book: book)
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

      response "409", "既に本棚に登録済み" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784873116068" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          book = create(:book, isbn: "9784873116068")
          create(:user_book, user: user, book: book)
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

      response "422", "isbn が13桁の数字でない" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "invalid_isbn" }

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

      response "503", "楽天書籍APIがエラー" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784873116068" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
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
              }
            }
          }

        run_test!
      end
    end

    delete "読みたいリストから書籍を削除する" do
      tags "読みたい系"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :isbn, in: :path, type: :string, required: true,
        description: "ISBN-13形式（13桁の数字のみ）"

      let(:user) { create(:user) }

      response "200", "削除成功（読みたいリストに存在する書籍）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784873116068" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          book = create(:book, isbn: "9784873116068")
          create(:want_to_read, user: user, book: book)
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "読みたいリストから削除しました" }
          },
          required: %w[message]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to eq("読みたいリストから削除しました")
        end
      end

      response "200", "削除成功（読みたいリストに存在しない書籍でも200を返す）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784873116068" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          create(:book, isbn: "9784873116068")
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "読みたいリストから削除しました" }
          },
          required: %w[message]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to eq("読みたいリストから削除しました")
        end
      end

      response "200", "削除成功（DBに書籍自体が存在しない場合も200を返す）" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "9784873116068" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "読みたいリストから削除しました" }
          },
          required: %w[message]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to eq("読みたいリストから削除しました")
        end
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:isbn) { "9784873116068" }

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

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.dig("error", "code")).to eq("UNAUTHORIZED")
        end
      end

      response "422", "isbn が13桁の数字でない" do
        let(:Authorization) { "Bearer valid_token" }
        let(:isbn) { "invalid_isbn" }

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
