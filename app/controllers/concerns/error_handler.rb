module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ClerkClient::UnauthorizedError, InvalidRefreshTokenError, with: :render_unauthorized
    rescue_from UserNotFoundError, with: :render_not_found
    rescue_from AccountAlreadyExistsError, with: :render_account_already_exists
    rescue_from UsernameTakenError, with: :render_username_taken
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
    rescue_from BadRequestError, with: :render_bad_request
    rescue_from ValidationError, with: :render_validation_error
    rescue_from AvatarFileError, with: :render_avatar_file_error
    rescue_from S3UploadError, with: :render_internal_server_error
  end

  private

  def render_unauthorized(e)
    Rails.logger.warn "認証失敗: #{e.class}"
    render json: {
      error: {
        code: ErrorCodes::UNAUTHORIZED,
        message: I18n.t("messages.errors.unauthorized")
      }
    }, status: :unauthorized
  end

  def render_not_found
    Rails.logger.warn "リソースが見つかりません: UserNotFoundError"
    render json: {
      error: {
        code: ErrorCodes::NOT_FOUND,
        message: I18n.t("messages.errors.not_found")
      }
    }, status: :not_found
  end

  def render_account_already_exists
    Rails.logger.warn "登録済みアカウント: clerk_user_id が重複"
    render json: {
      error: {
        code: ErrorCodes::ACCOUNT_ALREADY_EXISTS,
        message: I18n.t("messages.errors.account_already_exists")
      }
    }, status: :conflict
  end

  def render_username_taken
    Rails.logger.warn "username 重複"
    render json: {
      error: {
        code: ErrorCodes::USERNAME_TAKEN,
        message: I18n.t("messages.errors.username_taken")
      }
    }, status: :conflict
  end

  def render_bad_request(e)
    Rails.logger.warn "不正なリクエスト: #{e.message}"
    render json: {
      error: {
        code: ErrorCodes::BAD_REQUEST,
        message: I18n.t("messages.errors.bad_request")
      }
    }, status: :bad_request
  end

  def render_validation_error(e)
    Rails.logger.warn "バリデーションエラー: #{e.message}"
    render json: {
      error: {
        code: ErrorCodes::VALIDATION_ERROR,
        message: I18n.t("messages.errors.validation_error")
      }
    }, status: :unprocessable_entity
  end

  def render_avatar_file_error(e)
    Rails.logger.warn "アバターファイルエラー: #{e.message}"
    render json: {
      error: {
        code: ErrorCodes::UNPROCESSABLE_ENTITY,
        message: I18n.t("messages.errors.unprocessable_entity")
      }
    }, status: :unprocessable_entity
  end

  def render_internal_server_error(e)
    Rails.logger.error "内部サーバーエラー: #{e.class} #{e.message}"
    render json: {
      error: {
        code: ErrorCodes::INTERNAL_SERVER_ERROR,
        message: I18n.t("messages.errors.internal_server_error")
      }
    }, status: :internal_server_error
  end

  def render_unprocessable_entity(e)
    Rails.logger.warn "RecordInvalid: #{e.message}"
    details = e.record.errors.map do |error|
      { field: error.attribute, message: error.full_message }
    end

    render json: {
      error: {
        code: ErrorCodes::UNPROCESSABLE_ENTITY,
        message: I18n.t("messages.errors.unprocessable_entity"),
        details: details
      }
    }, status: :unprocessable_entity
  end
end
