FactoryBot.define do
  factory :user_book do
    association :user
    association :book
    content { nil }
  end
end
