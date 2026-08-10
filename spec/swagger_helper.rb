require "rails_helper"
require "rswag/specs"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are located
  # This is used by the swagger_helper to store generated Swagger files
  # NOTE: If you're using rswag-api and rswag-ui, you'll need to ensure
  # that it's configured to generate files in the same folder
  config.openapi_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # rswag-specs example group and providing the document name of the target swagger_doc,
  # e.g. describe 'api', swagger_doc: 'v2/swagger.yaml' do
  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Shelfie API V1",
        version: "v1",
        description: "Shelfie バックエンド API ドキュメント"
      },
      servers: [
        {
          url: "http://localhost:8080",
          description: "開発環境"
        }
      ],
      components: {
        securitySchemes: {
          Bearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT",
            description: "アクセストークン（自前発行の JWT）"
          }
        },
        schemas: {}
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to match the filename with the default output format
  # of 'json' here.
  config.openapi_format = :yaml
end
