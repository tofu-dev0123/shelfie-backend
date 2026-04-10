FactoryBot.define do
  factory :user_book_purchase_link do
    association :user_book
    url { "https://www.amazon.co.jp/dp/xxxxxxxx" }
  end
end
