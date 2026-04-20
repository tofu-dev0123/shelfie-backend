require "rails_helper"

RSpec.describe Follows::FollowingService, type: :service do
  let(:target_user) { create(:user, username: "komusan") }

  describe ".call" do
    context "正常系" do
      it "フォロー中一覧を返す" do
        followee = create(:user, username: "followee1", nickname: "フォロー中1")
        create(:follow, follower: target_user, followee: followee)

        result = described_class.call(username: target_user.username)

        expect(result[:items].size).to eq(1)
        expect(result[:items].first[:username]).to eq("followee1")
        expect(result[:items].first[:nickname]).to eq("フォロー中1")
      end

      it "ユーザーが存在しない場合も空の items を返す" do
        result = described_class.call(username: "not_exists_user")

        expect(result[:items]).to eq([])
        expect(result[:pagination][:has_next]).to eq(false)
        expect(result[:pagination][:next_cursor]).to be_nil
      end

      it "フォロー中0件でも空の items を返す" do
        result = described_class.call(username: target_user.username)

        expect(result[:items]).to eq([])
        expect(result[:pagination][:has_next]).to eq(false)
      end

      it "limit が50超のときクランプされる" do
        51.times do
          followee = create(:user)
          create(:follow, follower: target_user, followee: followee)
        end

        result = described_class.call(username: target_user.username, limit: 100)

        expect(result[:items].size).to eq(50)
        expect(result[:pagination][:has_next]).to eq(true)
      end

      it "新しくフォローした順に返る（follows.id DESC）" do
        f1 = create(:user, username: "old_followee")
        f2 = create(:user, username: "new_followee")
        create(:follow, follower: target_user, followee: f1)
        create(:follow, follower: target_user, followee: f2)

        result = described_class.call(username: target_user.username)

        expect(result[:items].map { |i| i[:username] }).to eq(%w[new_followee old_followee])
      end

      it "cursor を指定して次ページを取得できる" do
        f1 = create(:user, username: "f1_user")
        f2 = create(:user, username: "f2_user")
        create(:follow, follower: target_user, followee: f1)
        create(:follow, follower: target_user, followee: f2)

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
