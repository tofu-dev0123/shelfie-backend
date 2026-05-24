module Avatars
  class UploadService
    def self.call(current_user:, file:)
      raise BadRequestError, I18n.t("messages.errors.bad_request") unless file.respond_to?(:content_type)

      unless AvatarConstants::ALLOWED_CONTENT_TYPES.include?(file.content_type)
        raise AvatarFileError, I18n.t("messages.avatar.invalid_format")
      end

      if file.size > AvatarConstants::MAX_FILE_SIZE
        raise AvatarFileError, I18n.t("messages.avatar.file_too_large")
      end

      # キーをアップロードのたびにユニークにし、CDN/ブラウザのキャッシュにより
      # 古い画像が表示され続ける問題を回避する。
      old_key = current_user.avatar_key
      new_key = "#{AvatarConstants::S3_KEY_PREFIX}/#{current_user.id}_#{SecureRandom.hex(8)}"
      S3Client.upload(file: file, key: new_key)

      current_user.update!(avatar_key: new_key)

      # 旧オブジェクトはベストエフォートで削除し、失敗してもアップロード自体は成功扱いとする
      if old_key.present? && old_key != new_key
        begin
          S3Client.delete(key: old_key)
        rescue StandardError => e
          Rails.logger.warn "Avatars::UploadService: 旧アバター削除失敗 user_id=#{current_user.id} key=#{old_key} error=#{e.message}"
        end
      end

      Rails.logger.info "Avatars::UploadService: user_id=#{current_user.id} のアバターをアップロードしました"

      avatar_url(new_key)
    end

    def self.avatar_url(key)
      CdnConstants.url_for(key)
    end
    private_class_method :avatar_url
  end
end
