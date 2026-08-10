require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    context "正常系" do
      it "全項目が正しければ有効" do
        expect(build(:user)).to be_valid
      end

      it "username は大文字でも小文字に正規化されて有効" do
        user = build(:user, username: "TestUser")
        user.valid?
        expect(user.username).to eq("testuser")
      end

      it "bio は空でも有効" do
        expect(build(:user, bio: nil)).to be_valid
      end
    end

    context "email" do
      it "空のとき無効" do
        expect(build(:user, email: "")).not_to be_valid
      end

      it "重複のとき無効" do
        create(:user, email: "dup@example.com")
        expect(build(:user, email: "dup@example.com")).not_to be_valid
      end

      it "形式が不正のとき無効" do
        expect(build(:user, email: "not-an-email")).not_to be_valid
      end
    end

    context "nickname" do
      it "空のとき無効" do
        expect(build(:user, nickname: "")).not_to be_valid
      end

      it "51文字以上のとき無効" do
        expect(build(:user, nickname: "a" * 51)).not_to be_valid
      end

      it "50文字のとき有効" do
        expect(build(:user, nickname: "a" * 50)).to be_valid
      end
    end

    context "username" do
      it "空のとき無効" do
        expect(build(:user, username: "")).not_to be_valid
      end

      it "重複のとき無効" do
        create(:user, username: "dupuser")
        expect(build(:user, username: "dupuser")).not_to be_valid
      end

      it "4文字のとき有効" do
        expect(build(:user, username: "abcd")).to be_valid
      end

      it "41文字以上のとき無効" do
        expect(build(:user, username: "a" * 41)).not_to be_valid
      end

      it "40文字のとき有効" do
        expect(build(:user, username: "a" * 40)).to be_valid
      end

      it "日本語を含むとき無効" do
        expect(build(:user, username: "コムさん")).not_to be_valid
      end

      it "ハイフンを含むとき無効" do
        expect(build(:user, username: "ko-mu")).not_to be_valid
      end

      it "アンダースコアを含むとき有効" do
        expect(build(:user, username: "ko_mu")).to be_valid
      end
    end
  end
end
