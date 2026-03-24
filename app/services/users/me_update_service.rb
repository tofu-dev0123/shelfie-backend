module Users
  class MeUpdateService
    def self.call(current_user:, attrs:)
      # 更新フィールドが1つもない場合は不正リクエストとして弾く
      raise BadRequestError, "更新フィールドが指定されていません" if attrs.empty?

      current_user.update!(attrs)

      Rails.logger.info "Users::MeUpdateService: user_id=#{current_user.id} のプロフィールを更新しました"

      current_user
    end
  end
end
