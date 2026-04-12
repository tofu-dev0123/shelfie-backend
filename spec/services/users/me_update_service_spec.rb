require "rails_helper"

RSpec.describe Users::MeUpdateService, type: :service do
  let(:user) { create(:user) }

  describe ".call" do
    context "正常系" do
      it "nickname を更新できる" do
        described_class.call(current_user: user, attrs: { nickname: "新しい名前" })
        expect(user.reload.nickname).to eq("新しい名前")
      end

      it "bio を更新できる" do
        described_class.call(current_user: user, attrs: { bio: "新しい自己紹介" })
        expect(user.reload.bio).to eq("新しい自己紹介")
      end

      it "links を新規作成できる" do
        described_class.call(current_user: user, attrs: { links: [ "https://github.com/komusan" ] })
        expect(user.user_links.map(&:url)).to eq([ "https://github.com/komusan" ])
      end

      it "links を全件置き換えできる" do
        create(:user_link, user: user, url: "https://old.example.com")
        described_class.call(current_user: user, attrs: { links: [ "https://new.example.com" ] })
        expect(user.user_links.map(&:url)).to eq([ "https://new.example.com" ])
      end

      it "links: [] で全件削除できる" do
        create(:user_link, user: user)
        described_class.call(current_user: user, attrs: { links: [] })
        expect(user.user_links).to be_empty
      end

      it "links キーなしでリンクを変更しない" do
        create(:user_link, user: user, url: "https://github.com/komusan")
        described_class.call(current_user: user, attrs: { nickname: "新しい名前" })
        expect(user.user_links.count).to eq(1)
      end

      it "更新後の user を返す" do
        result = described_class.call(current_user: user, attrs: { nickname: "新しい名前" })
        expect(result).to eq(user)
      end
    end

    context "異常系" do
      it "全フィールド未送信のとき BadRequestError を raise する" do
        expect { described_class.call(current_user: user, attrs: {}) }
          .to raise_error(BadRequestError)
      end

      it "links が6件以上のとき ActiveRecord::RecordInvalid を raise する" do
        links = (1..6).map { |i| "https://example.com/#{i}" }
        expect { described_class.call(current_user: user, attrs: { links: links }) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it "links に不正なURLが含まれるとき ActiveRecord::RecordInvalid を raise する" do
        expect { described_class.call(current_user: user, attrs: { links: [ "not-a-url" ] }) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it "nickname が51文字以上のとき ActiveRecord::RecordInvalid を raise する" do
        expect { described_class.call(current_user: user, attrs: { nickname: "あ" * 51 }) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
