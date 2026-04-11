class Tag < ApplicationRecord
  has_many :user_book_tags, dependent: :destroy
  has_many :user_books, through: :user_book_tags
end
