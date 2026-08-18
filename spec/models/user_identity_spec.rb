require "rails_helper"

RSpec.describe UserIdentity, type: :model do
  describe "バリデーション" do
    context "正常系" do
      it "全項目が正しければ有効" do
        expect(build(:user_identity)).to be_valid
      end

      it "同一ユーザーでもプロバイダが違えば有効" do
        user = create(:user)
        create(:user_identity, user: user, provider: "google")

        expect(build(:user_identity, user: user, provider: "github")).to be_valid
      end
    end

    context "user" do
      it "無いとき無効" do
        expect(build(:user_identity, user: nil)).not_to be_valid
      end
    end

    context "provider" do
      it "空のとき無効" do
        expect(build(:user_identity, provider: "")).not_to be_valid
      end

      it "許可されていないプロバイダのとき無効" do
        expect(build(:user_identity, provider: "twitter")).not_to be_valid
      end

      it "大文字でも小文字に正規化されて有効" do
        identity = build(:user_identity, provider: "GOOGLE")
        identity.valid?
        expect(identity.provider).to eq("google")
      end

      it "表記ゆれでは二重連携できない" do
        user = create(:user)
        create(:user_identity, user: user, provider: "google")

        expect(build(:user_identity, user: user, provider: "Google")).not_to be_valid
      end
    end

    context "provider_uid" do
      it "空のとき無効" do
        expect(build(:user_identity, provider_uid: "")).not_to be_valid
      end

      it "同一の (provider, provider_uid) を持つ2件目は無効" do
        create(:user_identity, provider: "google", provider_uid: "dup_uid")

        expect(build(:user_identity, provider: "google", provider_uid: "dup_uid")).not_to be_valid
      end

      it "provider が違えば同じ provider_uid でも有効" do
        create(:user_identity, provider: "google", provider_uid: "same_uid")

        expect(build(:user_identity, provider: "github", provider_uid: "same_uid")).to be_valid
      end

      it "上限を超える長さのとき無効" do
        too_long = "a" * (UserIdentityConstants::PROVIDER_UID_MAX_LENGTH + 1)
        expect(build(:user_identity, provider_uid: too_long)).not_to be_valid
      end
    end

    context "email" do
      it "空のとき無効" do
        expect(build(:user_identity, email: "")).not_to be_valid
      end

      it "形式が不正のとき無効" do
        expect(build(:user_identity, email: "not-an-email")).not_to be_valid
      end

      it "上限を超える長さのとき無効" do
        too_long = "#{'a' * UserIdentityConstants::EMAIL_MAX_LENGTH}@example.com"
        expect(build(:user_identity, email: too_long)).not_to be_valid
      end
    end

    context "user_id と provider の組み合わせ" do
      it "同一の (user_id, provider) を持つ2件目は無効" do
        user = create(:user)
        create(:user_identity, user: user, provider: "google")

        expect(build(:user_identity, user: user, provider: "google")).not_to be_valid
      end
    end
  end

  describe "アソシエーション" do
    it "user を destroy すると紐づく user_identities も削除される" do
      user = create(:user)
      create(:user_identity, user: user)

      expect { user.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
