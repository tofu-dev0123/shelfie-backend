require "swagger_helper"

RSpec.describe "本棚系", type: :request do
  path "/v1/users/{username}/books" do
    get "本棚一覧取得API" do
      tags "本棚系"
      produces "application/json"

      parameter name: :username, in: :path, type: :string, required: true,
        description: "取得するユーザーの username"
      parameter name: :cursor, in: :query, type: :string, required: false,
        description: "前回レスポンスの next_cursor。不正な値の場合は 422 を返す"
      parameter name: :limit, in: :query, type: :integer, required: false,
        description: "最大取得件数。上限は50で、超えた場合は50にクランプされる（デフォルト20）"

      response "200", "本棚一覧取得成功" do
        let(:user) { create(:user, username: "komusan") }
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
                      google_books_id: { type: :string, example: "xxxxxxxx" },
                      title:           { type: :string, example: "リーダブルコード" },
                      authors:         { type: :array, items: { type: :string }, example: [ "著者名" ] },
                      thumbnail_url:   { type: :string, nullable: true, example: nil }
                    },
                    required: %w[google_books_id title authors thumbnail_url]
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

      response "200", "本棚が空" do
        let(:user) { create(:user) }
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
        let(:username) { user.username }
        let!(:user_books) { create_list(:user_book, 3, user: user) }
        let(:cursor) { Base64.strict_encode64({ id: user_books.second.id }.to_json) }

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
end
