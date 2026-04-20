module Follows
  class CreateService
    def self.call(current_user:, username:)
      validate_not_self!(current_user, username)

      followee = User.find_by(username: username)
      raise RecordNotFoundError unless followee

      Follow.create!(follower: current_user, followee: followee)

      Rails.logger.info "Follows::CreateService: follower_id=#{current_user.id} followee_id=#{followee.id} フォローしました"
    rescue ActiveRecord::RecordNotUnique
      raise FollowAlreadyExistsError
    end

    # 自分自身へのフォローは DB 側の check_constraint でも防がれるが、
    # 422 VALIDATION_ERROR として明示的に返すためサービス層でも検証する
    def self.validate_not_self!(current_user, username)
      raise ValidationError, I18n.t("follows.errors.self_follow_forbidden") if current_user.username == username
    end
    private_class_method :validate_not_self!
  end
end
