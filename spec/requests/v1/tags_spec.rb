require "swagger_helper"

RSpec.describe "タグ系", type: :request do
  path "/v1/tags" do
    get "タグ一覧取得API" do
      tags "タグ系"
      produces "application/json"

      response "200", "タグ一覧取得成功" do
        before do
          create(:tag, name: "Go")
          create(:tag, name: "GraphQL")
          create(:tag, name: "Ruby")
        end

        schema type: :object,
          properties: {
            tags: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  name: { type: :string, example: "Go" }
                },
                required: %w[name]
              }
            }
          },
          required: %w[tags]

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["tags"].map { |t| t["name"] }).to eq(%w[Go GraphQL Ruby])
        end
      end

      response "200", "タグが0件" do
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
    end
  end
end
