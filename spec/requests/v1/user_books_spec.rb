require "swagger_helper"

RSpec.describe "本棚系", type: :request do
  path "/v1/users/{username}/books" do
    get "本棚一覧取得API" do
      tags "本棚系"
      produces "application/json"

      parameter name: :Authorization, in: :header, type: :string, required: false,
        description: "アクセストークン。任意。指定時は book.is_in_my_want_to_read が boolean になる（未指定時は null）"
      parameter name: :username, in: :path, type: :string, required: true,
        description: "取得するユーザーの username"
      parameter name: :cursor, in: :query, type: :string, required: false,
        description: "前回レスポンスの next_cursor。不正な値の場合は 422 を返す"
      parameter name: :limit, in: :query, type: :integer, required: false,
        description: "最大取得件数。上限は50で、超えた場合は50にクランプされる（デフォルト20）"

      response "200", "本棚一覧取得成功" do
        let(:user) { create(:user, username: "komusan") }
        let(:Authorization) { nil }
        let(:username) { user.username }
        let(:book) { create(:book) }
        let(:user_book) { create(:user_book, user: user, book: book, content: "とても良い本でした") }
        let(:tag) { create(:tag, name: "Go") }

        before { create(:user_book_tag, user_book: user_book, tag: tag) }

        schema type: :object,
          properties: {
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id:         { type: :integer, example: 1 },
                  content:    { type: :string, nullable: true, example: "とても良い本でした" },
                  tags:       { type: :array, items: { type: :string }, example: [ "Go" ] },
                  created_at: { type: :string, example: "2026-03-05T00:00:00Z" },
                  book: {
                    type: :object,
                    properties: {
                      isbn:                  { type: :string, example: "9784873118079" },
                      title:                 { type: :string, example: "リーダブルコード" },
                      authors:               { type: :array, items: { type: :string }, example: [ "著者名" ] },
                      thumbnail_url:         { type: :string, nullable: true, example: nil },
                      is_in_my_want_to_read: { type: :boolean, nullable: true, example: nil, description: "ログイン中ユーザーが読みたいリストに登録しているか。未ログイン時は null" }
                    },
                    required: %w[isbn title authors thumbnail_url is_in_my_want_to_read]
                  }
                },
                required: %w[id content tags created_at book]
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

        run_test!
      end

      response "200", "ログイン中ユーザーが対象書籍を読みたい登録済み" do
        let(:viewer) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:user) { create(:user) }
        let(:username) { user.username }
        let(:book) { create(:book) }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => viewer.id })
          create(:user_book, user: user, book: book)
          create(:want_to_read, user: viewer, book: book)
        end

        schema type: :object,
          properties: {
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  book: {
                    type: :object,
                    properties: {
                      is_in_my_want_to_read: { type: :boolean, nullable: true, example: true }
                    },
                    required: %w[is_in_my_want_to_read]
                  }
                }
              }
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["items"].first["book"]["is_in_my_want_to_read"]).to eq(true)
        end
      end

      response "200", "本棚が空" do
        let(:user) { create(:user) }
        let(:Authorization) { nil }
        let(:username) { user.username }

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

      response "200", "cursor 指定でページネーション" do
        let(:user) { create(:user) }
        let(:Authorization) { nil }
        let(:username) { user.username }
        let!(:user_books) { create_list(:user_book, 3, user: user) }
        let(:cursor) { CompoundCursor.encode(created_at: user_books.second.created_at, id: user_books.second.id) }

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
          expect(data["items"].size).to eq(1)
        end
      end

      response "404", "ユーザーが存在しない" do
        let(:Authorization) { nil }
        let(:username) { "nonexistent_user" }

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

      response "422", "不正なカーソル値" do
        let(:user) { create(:user) }
        let(:Authorization) { nil }
        let(:username) { user.username }
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
    end
  end

  path "/v1/users/{username}/books/{isbn}" do
    get "本棚投稿詳細取得API" do
      tags "本棚系"
      produces "application/json"

      parameter name: :Authorization, in: :header, type: :string, required: false,
        description: "アクセストークン。任意。指定時は book.is_in_my_want_to_read が boolean になる（未指定時は null）"
      parameter name: :username, in: :path, type: :string, required: true,
        description: "投稿したユーザーの username"
      parameter name: :isbn, in: :path, type: :string, required: true,
        description: "書籍の ISBN-13"

      response "200", "投稿詳細取得成功" do
        let(:user) { create(:user, username: "komusan") }
        let(:Authorization) { nil }
        let(:book) { create(:book) }
        let(:user_book) { create(:user_book, user: user, book: book, content: "とても良い本でした") }
        let(:tag) { create(:tag, name: "Go") }
        let(:username) { user.username }
        let(:isbn) { book.isbn }

        before do
          create(:user_book_tag, user_book: user_book, tag: tag)
        end

        schema type: :object,
          properties: {
            id:         { type: :integer, example: 1 },
            content:    { type: :string, nullable: true, example: "とても良い本でした" },
            tags:       { type: :array, items: { type: :string }, example: [ "Go" ] },
            created_at: { type: :string, example: "2026-03-05T00:00:00Z" },
            updated_at: { type: :string, example: "2026-03-06T00:00:00Z" },
            book: {
              type: :object,
              properties: {
                isbn:                  { type: :string, example: "9784873118079" },
                title:                 { type: :string, example: "リーダブルコード" },
                authors:               { type: :array, items: { type: :string }, example: [ "著者名" ] },
                thumbnail_url:         { type: :string, nullable: true, example: nil },
                is_in_my_want_to_read: { type: :boolean, nullable: true, example: nil, description: "ログイン中ユーザーが読みたいリストに登録しているか。未ログイン時は null" }
              },
              required: %w[isbn title authors thumbnail_url is_in_my_want_to_read]
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
          required: %w[id content tags created_at updated_at book user]

        run_test!
      end

      response "200", "ログイン中ユーザーが対象書籍を読みたい登録済み" do
        let(:viewer) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:user) { create(:user) }
        let(:book) { create(:book) }
        let!(:user_book) { create(:user_book, user: user, book: book) }
        let(:username) { user.username }
        let(:isbn) { book.isbn }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => viewer.id })
          create(:want_to_read, user: viewer, book: book)
        end

        schema type: :object,
          properties: {
            book: {
              type: :object,
              properties: {
                is_in_my_want_to_read: { type: :boolean, nullable: true, example: true }
              },
              required: %w[is_in_my_want_to_read]
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["book"]["is_in_my_want_to_read"]).to eq(true)
        end
      end


      response "404", "ユーザーが存在しない" do
        let(:Authorization) { nil }
        let(:username) { "nonexistent_user" }
        let(:isbn) { "9784000000001" }

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

      response "404", "投稿が存在しない" do
        let(:user) { create(:user) }
        let(:Authorization) { nil }
        let(:username) { user.username }
        let(:isbn) { "9784000000001" }

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
    end
  end
end
