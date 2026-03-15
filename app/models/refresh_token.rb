class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true
  validates :expires_at, presence: true
end
