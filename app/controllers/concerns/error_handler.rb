module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ClerkClient::UnauthorizedError, with: :render_unauthorized
    rescue_from AccountAlreadyExistsError, with: :render_account_already_exists
    rescue_from UsernameTakenError, with: :render_username_taken
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  end

  private

  def render_unauthorized
    Rails.logger.warn "認証失敗: Clerk JWT が無効"
    render json: {
      error: {
        code: ErrorCodes::UNAUTHORIZED,
        message: "認証に失敗しました"
      }
    }, status: :unauthorized
  end

  def render_account_already_exists
    Rails.logger.warn "登録済みアカウント: clerk_user_id が重複"
    render json: {
      error: {
        code: ErrorCodes::ACCOUNT_ALREADY_EXISTS,
        message: "すでに登録済みのアカウントです"
      }
    }, status: :conflict
  end

  def render_username_taken
    Rails.logger.warn "username 重複"
    render json: {
      error: {
        code: ErrorCodes::USERNAME_TAKEN,
        message: "このユーザー名はすでに使用されています"
      }
    }, status: :conflict
  end

  def render_unprocessable_entity(e)
    Rails.logger.error "RecordInvalid: #{e.message}"
    details = e.record.errors.map do |error|
      { field: error.attribute, message: error.full_message }
    end

    render json: {
      error: {
        code: ErrorCodes::UNPROCESSABLE_ENTITY,
        message: "入力内容に誤りがあります",
        details: details
      }
    }, status: :unprocessable_entity
  end
end
