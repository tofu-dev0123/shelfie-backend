class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true
  validates :expires_at, presence: true

  scope :valid, -> { where("expires_at > ?", Time.current) }
end
