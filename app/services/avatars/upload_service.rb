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

      key = "#{AvatarConstants::S3_KEY_PREFIX}/#{current_user.id}"
      S3Client.upload(file: file, key: key)

      current_user.update!(avatar_key: key)

      Rails.logger.info "Avatars::UploadService: user_id=#{current_user.id} のアバターをアップロードしました"

      avatar_url(key)
    end

    def self.avatar_url(key)
      CdnConstants.url_for(key)
    end
    private_class_method :avatar_url
  end
end
