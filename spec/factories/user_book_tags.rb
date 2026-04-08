FactoryBot.define do
  factory :user_book_tag do
    association :user_book
    association :tag
  end
end
