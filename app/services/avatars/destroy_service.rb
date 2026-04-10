module Avatars
  class DestroyService
    def self.call(current_user:)
      unless current_user.avatar_key
        Rails.logger.info "Avatars::DestroyService: user_id=#{current_user.id} アバターなし（スキップ）"
        return
      end

      S3Client.delete(key: current_user.avatar_key)
      current_user.update!(avatar_key: nil)

      Rails.logger.info "Avatars::DestroyService: user_id=#{current_user.id} のアバターを削除しました"
    end
  end
end
