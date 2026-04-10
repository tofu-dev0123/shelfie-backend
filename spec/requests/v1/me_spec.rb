require "swagger_helper"

RSpec.describe "マイページ系", type: :request do
  path "/v1/me" do
    get "マイプロフィール取得API" do
      tags "マイページ系"
      produces "application/json"
      security [ Bearer: [] ]

      response "200", "プロフィール取得成功" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            id:              { type: :integer, example: 1 },
            username:        { type: :string, example: "komusan" },
            nickname:        { type: :string, example: "コムさん" },
            bio:             { type: :string, nullable: true, example: "エンジニアです" },
            avatar_url:      { type: :string, nullable: true, example: nil },
            followers_count: { type: :integer, example: 0 },
            following_count: { type: :integer, example: 0 },
            books_count:     { type: :integer, example: 0 },
            links:           { type: :array, items: { type: :string }, example: [] },
            is_me:           { type: :boolean, example: true }
          },
          required: %w[id username nickname bio avatar_url followers_count following_count books_count links is_me]

        run_test!
      end

      response "401", "アクセストークンが無効・期限切れ" do
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
              }
            }
          }

        run_test!
      end

      response "401", "アクセストークンなし" do
        # Authorization ヘッダーを送らないことで 401 を確認する
        let(:Authorization) { nil }

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
    end

    patch "プロフィール更新API" do
      tags "マイページ系"
      consumes "application/json"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          nickname: { type: :string, example: "コムさん" },
          bio:      { type: :string, example: "エンジニアです" },
          links:    { type: :array, items: { type: :string }, example: [ "https://github.com/komusan" ] }
        }
      }

      let(:success_schema) do
        {
          type: :object,
          properties: {
            nickname: { type: :string, example: "コムさん" },
            bio:      { type: :string, nullable: true, example: "エンジニアです" },
            links:    { type: :array, items: { type: :string }, example: [] }
          },
          required: %w[nickname bio links]
        }
      end

      response "200", "プロフィール更新成功（nickname・bio）" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { nickname: "コムさん", bio: "エンジニアです" } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            nickname: { type: :string, example: "コムさん" },
            bio:      { type: :string, nullable: true, example: "エンジニアです" },
            links:    { type: :array, items: { type: :string }, example: [] }
          },
          required: %w[nickname bio links]

        run_test!
      end

      response "200", "プロフィール更新成功（links置き換え）" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { links: [ "https://github.com/komusan", "https://x.com/komusan" ] } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            nickname: { type: :string, example: "コムさん" },
            bio:      { type: :string, nullable: true, example: "エンジニアです" },
            links:    { type: :array, items: { type: :string }, example: [ "https://github.com/komusan" ] }
          },
          required: %w[nickname bio links]

        run_test!
      end

      response "200", "プロフィール更新成功（links全件削除）" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { links: [] } }

        before do
          create(:user_link, user: user)
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            nickname: { type: :string, example: "コムさん" },
            bio:      { type: :string, nullable: true, example: "エンジニアです" },
            links:    { type: :array, items: { type: :string }, example: [] }
          },
          required: %w[nickname bio links]

        run_test!
      end

      response "400", "全フィールド未送信" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { {} }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "BAD_REQUEST" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end

      response "401", "アクセストークンが無効・期限切れ" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:body) { { nickname: "コムさん" } }

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
        let(:body) { { nickname: "コムさん" } }

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

      response "422", "バリデーションエラー（nickname超過）" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { nickname: "あ" * 51 } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "UNPROCESSABLE_ENTITY" },
                message: { type: :string },
                details: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      field:   { type: :string, example: "nickname" },
                      message: { type: :string, example: "ニックネームは50文字以内で入力してください" }
                    }
                  }
                }
              }
            }
          }

        run_test!
      end

      response "422", "バリデーションエラー（links件数超過）" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { links: (1..6).map { |i| "https://example.com/#{i}" } } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "UNPROCESSABLE_ENTITY" },
                message: { type: :string },
                details: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      field:   { type: :string, example: "links" },
                      message: { type: :string, example: "リンクは5件以内で入力してください" }
                    }
                  }
                }
              }
            }
          }

        run_test!
      end

      response "422", "バリデーションエラー（links不正URL）" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:body) { { links: [ "not-a-url" ] } }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "UNPROCESSABLE_ENTITY" },
                message: { type: :string },
                details: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      field:   { type: :string, example: "links[0]" },
                      message: { type: :string, example: "正しいURL形式で入力してください" }
                    }
                  }
                }
              }
            }
          }

        run_test!
      end
    end
  end
end
