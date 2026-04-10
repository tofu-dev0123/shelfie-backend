class UserBookTag < ApplicationRecord
  belongs_to :user_book
  belongs_to :tag
end
