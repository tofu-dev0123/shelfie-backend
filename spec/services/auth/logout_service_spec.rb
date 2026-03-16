require "rails_helper"

RSpec.describe Auth::LogoutService, type: :service do
  describe ".call" do
    context "正常系" do
      it "リフレッシュトークンが存在するとき :logged_out を返し、レコードを削除する" do
        user = create(:user)
        create(:refresh_token, user: user, token: "valid_token")

        result = described_class.call(refresh_token: "valid_token")

        expect(result).to eq(:logged_out)
        expect(RefreshToken.find_by(token: "valid_token")).to be_nil
      end
    end

    context "異常系" do
      it "リフレッシュトークンが nil のとき :already_logged_out を返す" do
        result = described_class.call(refresh_token: nil)
        expect(result).to eq(:already_logged_out)
      end

      it "リフレッシュトークンが空文字のとき :already_logged_out を返す" do
        result = described_class.call(refresh_token: "")
        expect(result).to eq(:already_logged_out)
      end

      it "DBにレコードが存在しないとき :already_logged_out を返す" do
        result = described_class.call(refresh_token: "nonexistent_token")
        expect(result).to eq(:already_logged_out)
      end
    end
  end
end
