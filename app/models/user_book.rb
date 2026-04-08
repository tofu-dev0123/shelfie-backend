class UserBook < ApplicationRecord
  belongs_to :user
  belongs_to :book
  has_many :user_book_tags, dependent: :destroy
  has_many :tags, through: :user_book_tags
end
