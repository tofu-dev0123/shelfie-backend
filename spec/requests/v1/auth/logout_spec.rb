require "swagger_helper"

RSpec.describe "認証系", type: :request do
  path "/v1/auth/logout" do
    delete "ログアウトAPI" do
      tags "認証系"
      produces "application/json"

      response "200", "ログアウト成功" do
        let(:user) { create(:user) }
        let!(:refresh_token_record) do
          create(:refresh_token, user: user, token: "valid_refresh_token",
                                 expires_at: 30.days.from_now)
        end

        before do
          # Cookie にリフレッシュトークンをセット
          cookies[:refresh_token] = "valid_refresh_token"
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "ログアウトしました。" }
          },
          required: [ "message" ]

        # delete_cookie は set 時と同じ Path を指定しないとブラウザが削除と判定しないため、
        # Path=/ が Set-Cookie ヘッダに含まれていることを保証する
        run_test! do |response|
          expect(response.headers["Set-Cookie"]).to match(/refresh_token=/i)
          expect(response.headers["Set-Cookie"]).to match(/path=\//i)
        end
      end

      response "200", "すでにログアウト済み（Cookie なし）" do
        # Cookie なし → 冪等性で 200 を返す

        schema type: :object,
          properties: {
            message: { type: :string, example: "すでにログアウト済みです。" }
          },
          required: [ "message" ]

        run_test!
      end

      response "200", "すでにログアウト済み（DBにレコードなし）" do
        before do
          # Cookie はあるが DB にレコードが存在しない
          cookies[:refresh_token] = "nonexistent_token"
        end

        schema type: :object,
          properties: {
            message: { type: :string, example: "すでにログアウト済みです。" }
          },
          required: [ "message" ]

        run_test!
      end
    end
  end
end
