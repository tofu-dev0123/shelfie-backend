require "uri"

class User < ApplicationRecord
  has_many :refresh_tokens, dependent: :destroy
  has_many :user_links, dependent: :destroy
  has_many :user_books, dependent: :destroy
  has_many :user_identities, dependent: :destroy

  attr_accessor :links_input

  def links
    user_links.map(&:url)
  end

  # バリデーションの一意性チェック前に正規化することで、大文字小文字を区別しない一意性を保証する
  before_validation :normalize_username

  validates :clerk_user_id, presence: true, uniqueness: true
  validates :email,
    presence: true,
    uniqueness: true,
    # 標準ライブラリのREGEXPを使用することで外部gemなしにメール形式を検証できる
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :nickname, presence: true, length: { maximum: UserConstants::NICKNAME_MAX_LENGTH }
  validates :bio, length: { maximum: UserConstants::BIO_MAX_LENGTH }, allow_blank: true
  validates :username,
    presence: true,
    uniqueness: true,
    format: { with: UserConstants::USERNAME_REGEX },
    length: { minimum: UserConstants::USERNAME_MIN_LENGTH, maximum: UserConstants::USERNAME_MAX_LENGTH }
  validate :no_consecutive_underscores
  validate :validate_links_input, if: -> { !links_input.nil? }

  private

  def normalize_username
    username&.downcase!
  end

  def no_consecutive_underscores
    # username が nil の場合は presence バリデーションが拾うため、ここでは連続アンダースコアのみチェックする
    errors.add(:username, :consecutive_underscores) if username&.include?("__")
  end

  def validate_links_input
    if links_input.size > UserConstants::LINKS_MAX_COUNT
      errors.add(:links, :too_many, count: UserConstants::LINKS_MAX_COUNT)
      return
    end

    links_input.each_with_index do |url, i|
      errors.add(:links, "#{i + 1}件目のURLの形式が正しくありません") unless valid_link_url?(url)
    end
  end

  def valid_link_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end
end
