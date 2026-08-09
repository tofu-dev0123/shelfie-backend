class UserIdentity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true, uniqueness: { scope: :user_id }
  validates :provider_uid, presence: true, uniqueness: { scope: :provider }
  validates :email, presence: true
end
