require "swagger_helper"

RSpec.describe "タグ系", type: :request do
  path "/v1/tags" do
    get "タグサジェストAPI" do
      tags "タグ系"
      produces "application/json"

      parameter name: :q, in: :query, type: :string, required: true,
        description: "検索クエリ（部分一致・最大50文字）"

      response "200", "サジェスト結果（前方一致優先・部分一致）" do
        let(:q) { "Ru" }

        before do
          create(:tag, name: "Ruby")
          create(:tag, name: "Rust")
          create(:tag, name: "Rails")  # 部分一致しないので除外
          create(:tag, name: "Kubernetes")  # 部分一致しないので除外
        end

        schema type: :object,
          properties: {
            tags: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  name: { type: :string, example: "Ruby" }
                },
                required: %w[name]
              }
            }
          },
          required: %w[tags]

        run_test! do |response|
          data = JSON.parse(response.body)
          # Ruby / Rust は前方一致、Rails/Kubernetes は除外。Ruby と Rust は名前昇順
          expect(data["tags"].map { |t| t["name"] }).to eq(%w[Ruby Rust])
        end
      end

      response "200", "前方一致を部分一致より優先する" do
        let(:q) { "script" }

        before do
          create(:tag, name: "TypeScript")  # 部分一致（途中）
          create(:tag, name: "script")      # 前方一致
        end

        schema type: :object,
          properties: {
            tags: { type: :array, items: { type: :object, properties: { name: { type: :string } } } }
          },
          required: %w[tags]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["tags"].map { |t| t["name"] }).to eq(%w[script TypeScript])
        end
      end

      response "200", "ヒット0件" do
        let(:q) { "xyz_not_exist" }

        schema type: :object,
          properties: {
            tags: { type: :array, items: {}, example: [] }
          },
          required: %w[tags]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["tags"]).to eq([])
        end
      end

      response "422", "q を送信していない（パラメータ欠落）" do
        let(:q) { nil }

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

      response "422", "q が未指定（空文字）" do
        let(:q) { "" }

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

      response "422", "q が50文字超" do
        let(:q) { "a" * 51 }

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
