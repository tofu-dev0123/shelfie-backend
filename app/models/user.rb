require "uri"

class User < ApplicationRecord
  has_many :refresh_tokens, dependent: :destroy

  before_validation :normalize_username

  validates :clerk_user_id, presence: true, uniqueness: true
  validates :email,
    presence: true,
    uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :nickname, presence: true, length: { maximum: 50 }
  validates :username,
    presence: true,
    uniqueness: true,
    format: { with: /\A[a-zA-Z0-9_]+\z/ },
    length: { minimum: 4, maximum: 40 }

  private

  def normalize_username
    username&.downcase!
  end
end
