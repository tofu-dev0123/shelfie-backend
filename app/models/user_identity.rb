require "uri"

class UserIdentity < ApplicationRecord
  belongs_to :user

  # 一意性チェック前に正規化することで、大文字小文字を区別しない一意性を保証する
  before_validation :normalize_provider

  validates :provider,
    presence: true,
    uniqueness: { scope: :user_id },
    inclusion: { in: UserIdentityConstants::PROVIDERS }
  validates :provider_uid,
    presence: true,
    uniqueness: { scope: :provider },
    length: { maximum: UserIdentityConstants::PROVIDER_UID_MAX_LENGTH }
  validates :email,
    presence: true,
    length: { maximum: UserIdentityConstants::EMAIL_MAX_LENGTH },
    # 標準ライブラリのREGEXPを使用することで外部gemなしにメール形式を検証できる
    format: { with: URI::MailTo::EMAIL_REGEXP }

  private

  def normalize_provider
    provider&.downcase!
  end
end
