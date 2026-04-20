require "rails_helper"

RSpec.describe Follows::CreateService, type: :service do
  let(:current_user) { create(:user) }
  let(:target_user) { create(:user, username: "komusan") }

  describe ".call" do
    context "正常系" do
      it "Follow レコードが作成される" do
        expect { described_class.call(current_user: current_user, username: target_user.username) }
          .to change(Follow, :count).by(1)
      end

      it "follower/followee が正しく設定される" do
        described_class.call(current_user: current_user, username: target_user.username)
        follow = Follow.last
        expect(follow.follower_id).to eq(current_user.id)
        expect(follow.followee_id).to eq(target_user.id)
      end
    end

    context "異常系" do
      it "自分自身をフォローしようとしたとき ValidationError を raise する" do
        expect { described_class.call(current_user: current_user, username: current_user.username) }
          .to raise_error(ValidationError)
      end

      it "ユーザーが存在しないとき RecordNotFoundError を raise する" do
        expect { described_class.call(current_user: current_user, username: "not_exists_user") }
          .to raise_error(RecordNotFoundError)
      end

      it "既にフォロー済みのとき FollowAlreadyExistsError を raise する" do
        create(:follow, follower: current_user, followee: target_user)

        expect { described_class.call(current_user: current_user, username: target_user.username) }
          .to raise_error(FollowAlreadyExistsError)
      end
    end
  end
end
