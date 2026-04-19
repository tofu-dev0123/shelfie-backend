class Tag < ApplicationRecord
  has_many :user_book_tags, dependent: :destroy
  has_many :user_books, through: :user_book_tags

  scope :ordered, -> { order(:name) }

  # 並列リクエストで同名タグが同時作成されると tags.name の unique index で
  # ActiveRecord::RecordNotUnique が起きる。衝突時は作成済みレコードを再検索する。
  def self.find_or_create_safely!(name)
    find_or_create_by!(name: name)
  rescue ActiveRecord::RecordNotUnique
    find_by!(name: name)
  end
end
