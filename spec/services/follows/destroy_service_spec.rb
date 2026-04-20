require "rails_helper"

RSpec.describe Follows::DestroyService, type: :service do
  let(:current_user) { create(:user) }
  let(:target_user) { create(:user, username: "komusan") }

  describe ".call" do
    context "正常系" do
      it "フォロー済みのとき Follow レコードが削除される" do
        create(:follow, follower: current_user, followee: target_user)

        expect { described_class.call(current_user: current_user, username: target_user.username) }
          .to change(Follow, :count).by(-1)
      end

      it "フォローしていない場合も例外を raise しない（冪等）" do
        expect { described_class.call(current_user: current_user, username: target_user.username) }
          .not_to raise_error
      end

      it "ユーザーが存在しない場合も例外を raise しない（冪等）" do
        expect { described_class.call(current_user: current_user, username: "not_exists_user") }
          .not_to raise_error
      end
    end

    context "異常系" do
      it "自分自身のフォローを解除しようとしたとき ValidationError を raise する" do
        expect { described_class.call(current_user: current_user, username: current_user.username) }
          .to raise_error(ValidationError)
      end
    end
  end
end
