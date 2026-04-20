module Follows
  class DestroyService
    def self.call(current_user:, username:)
      validate_not_self!(current_user, username)

      # ユーザー・follows レコードが存在しない場合も正常終了する（冪等性：削除済みと同じ状態のため）
      followee = User.find_by(username: username)
      unless followee
        Rails.logger.info "Follows::DestroyService: follower_id=#{current_user.id} username=#{username} 対象ユーザーが存在しないため no-op"
        return
      end

      follow = Follow.find_by(follower_id: current_user.id, followee_id: followee.id)
      unless follow
        Rails.logger.info "Follows::DestroyService: follower_id=#{current_user.id} followee_id=#{followee.id} 未フォローのため no-op"
        return
      end

      follow.destroy!
      Rails.logger.info "Follows::DestroyService: follower_id=#{current_user.id} followee_id=#{followee.id} フォローを解除しました"
    end

    def self.validate_not_self!(current_user, username)
      raise ValidationError, I18n.t("follows.errors.self_unfollow_forbidden") if current_user.username == username
    end
    private_class_method :validate_not_self!
  end
end
