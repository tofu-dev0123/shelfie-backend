FactoryBot.define do
  factory :book do
    sequence(:isbn) { |n| "97800000#{n.to_s.rjust(5, '0')}" }
    title { "テスト本" }
    authors { [ "著者名" ] }
    thumbnail_url { nil }
  end
end
