require "swagger_helper"

RSpec.describe "マイページ系", type: :request do
  path "/v1/me/avatar" do
    post "アバター画像アップロードAPI" do
      tags "マイページ系"
      consumes "multipart/form-data"
      produces "application/json"
      security [ Bearer: [] ]

      parameter name: :avatar, in: :formData, type: :file, required: true,
                description: "アップロードする画像ファイル（JPEG / PNG / WebP、最大 5MB）"

      let(:error_schema) do
        {
          type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string },
                message: { type: :string }
              }
            }
          }
        }
      end

      response "200", "アップロード成功" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:avatar) do
          tempfile = Tempfile.new([ "avatar", ".jpg" ])
          tempfile.write("\xFF\xD8\xFF\xE0" + "x" * 100)
          tempfile.rewind
          Rack::Test::UploadedFile.new(tempfile, "image/jpeg")
        end

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          allow(S3Client).to receive(:upload).and_return("avatars/#{user.id}.jpg")
        end

        schema type: :object,
          properties: {
            avatar_url: { type: :string, nullable: true, example: "https://example.cloudfront.net/avatars/1.jpg" }
          },
          required: %w[avatar_url]

        run_test!
      end

      response "400", "avatar フィールドが未添付" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:avatar) { nil }

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
        let(:avatar) { nil }

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
        let(:avatar) { nil }

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

      response "422", "ファイル形式が不正（JPEG / PNG / WebP 以外）" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:avatar) do
          tempfile = Tempfile.new([ "document", ".pdf" ])
          tempfile.write("%PDF-1.4")
          tempfile.rewind
          Rack::Test::UploadedFile.new(tempfile, "application/pdf")
        end

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "UNPROCESSABLE_ENTITY" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end

      response "422", "ファイルサイズが 5MB 超" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:avatar) do
          tempfile = Tempfile.new([ "large_avatar", ".jpg" ])
          tempfile.write("\xFF\xD8\xFF\xE0")
          tempfile.truncate(6 * 1024 * 1024)
          tempfile.rewind
          Rack::Test::UploadedFile.new(tempfile, "image/jpeg")
        end

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "UNPROCESSABLE_ENTITY" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end

      response "500", "S3 アップロード失敗" do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer valid_token" }
        let(:avatar) do
          tempfile = Tempfile.new([ "avatar", ".jpg" ])
          tempfile.write("\xFF\xD8\xFF\xE0" + "x" * 100)
          tempfile.rewind
          Rack::Test::UploadedFile.new(tempfile, "image/jpeg")
        end

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          allow(S3Client).to receive(:upload).and_raise(S3UploadError)
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "INTERNAL_SERVER_ERROR" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end
    end

    delete "アバター画像削除API" do
      tags "マイページ系"
      produces "application/json"
      security [ Bearer: [] ]

      response "200", "削除成功（アバターあり）" do
        let(:user) { create(:user, avatar_key: "avatars/#{create(:user).id}") }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          allow(S3Client).to receive(:delete).and_return(true)
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "削除が完了しました" }
          },
          required: %w[message]

        run_test!
      end

      response "200", "削除成功（アバターなし・冪等）" do
        let(:user) { create(:user, avatar_key: nil) }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
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

      response "500", "S3 削除失敗" do
        let(:user) { create(:user, avatar_key: "avatars/#{create(:user).id}") }
        let(:Authorization) { "Bearer valid_token" }

        before do
          allow(TokenIssuer).to receive(:decode).with("valid_token").and_return({ "user_id" => user.id })
          allow(S3Client).to receive(:delete).and_raise(S3DeleteError)
        end

        schema type: :object,
          properties: {
            error: {
              type: :object,
              properties: {
                code:    { type: :string, example: "INTERNAL_SERVER_ERROR" },
                message: { type: :string }
              }
            }
          }

        run_test!
      end
    end
  end
end
