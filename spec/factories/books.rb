FactoryBot.define do
  factory :book do
    sequence(:google_books_id) { |n| "google_book_#{n}" }
    title { "テスト本" }
    authors { [ "著者名" ] }
    thumbnail_url { nil }
  end
end
