require "rails_helper"

RSpec.describe Follows::FollowersService, type: :service do
  let(:target_user) { create(:user, username: "komusan") }

  describe ".call" do
    context "正常系" do
      it "フォロワー一覧を返す" do
        follower = create(:user, username: "follower1", nickname: "フォロワー1")
        create(:follow, follower: follower, followee: target_user)

        result = described_class.call(username: target_user.username)

        expect(result[:items].size).to eq(1)
        expect(result[:items].first[:username]).to eq("follower1")
        expect(result[:items].first[:nickname]).to eq("フォロワー1")
      end

      it "ユーザーが存在しない場合も空の items を返す" do
        result = described_class.call(username: "not_exists_user")

        expect(result[:items]).to eq([])
        expect(result[:pagination][:has_next]).to eq(false)
        expect(result[:pagination][:next_cursor]).to be_nil
      end

      it "フォロワー0件でも空の items を返す" do
        result = described_class.call(username: target_user.username)

        expect(result[:items]).to eq([])
        expect(result[:pagination][:has_next]).to eq(false)
      end

      it "limit が50超のときクランプされる" do
        51.times do
          follower = create(:user)
          create(:follow, follower: follower, followee: target_user)
        end

        result = described_class.call(username: target_user.username, limit: 100)

        expect(result[:items].size).to eq(50)
        expect(result[:pagination][:has_next]).to eq(true)
      end

      it "新しくフォローされた順に返る（follows.id DESC）" do
        f1 = create(:user, username: "old_follower")
        f2 = create(:user, username: "new_follower")
        create(:follow, follower: f1, followee: target_user)
        create(:follow, follower: f2, followee: target_user)

        result = described_class.call(username: target_user.username)

        expect(result[:items].map { |i| i[:username] }).to eq(%w[new_follower old_follower])
      end

      it "cursor を指定して次ページを取得できる" do
        f1 = create(:user, username: "f1_user")
        f2 = create(:user, username: "f2_user")
        create(:follow, follower: f1, followee: target_user)
        create(:follow, follower: f2, followee: target_user)

        first_page = described_class.call(username: target_user.username, limit: 1)
        expect(first_page[:pagination][:has_next]).to eq(true)

        second_page = described_class.call(username: target_user.username, limit: 1, cursor: first_page[:pagination][:next_cursor])
        expect(second_page[:items].size).to eq(1)
        expect(second_page[:pagination][:has_next]).to eq(false)
      end
    end

    context "異常系" do
      it "不正な cursor のとき ValidationError を raise する" do
        expect { described_class.call(username: target_user.username, cursor: "invalid_cursor") }
          .to raise_error(ValidationError)
      end
    end
  end
end
