require "uri"

class User < ApplicationRecord
  USERNAME_REGEX = /\A[a-z0-9_]+\z/
  USERNAME_MIN_LENGTH = 3
  USERNAME_MAX_LENGTH = 40

  has_many :refresh_tokens, dependent: :destroy

  # バリデーションの一意性チェック前に正規化することで、大文字小文字を区別しない一意性を保証する
  before_validation :normalize_username

  validates :clerk_user_id, presence: true, uniqueness: true
  validates :email,
    presence: true,
    uniqueness: true,
    # 標準ライブラリのREGEXPを使用することで外部gemなしにメール形式を検証できる
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :nickname, presence: true, length: { maximum: 50 }
  validates :username,
    presence: true,
    uniqueness: true,
    # 英数字とアンダースコアのみ許可（URLセーフかつSNS的な標準に準拠）
    format: { with: USERNAME_REGEX },
    length: { minimum: USERNAME_MIN_LENGTH, maximum: USERNAME_MAX_LENGTH }
  validate :no_consecutive_underscores

  private

  def normalize_username
    username&.downcase!
  end

  def no_consecutive_underscores
    errors.add(:username, :consecutive_underscores) if username&.include?("__")
  end
end
