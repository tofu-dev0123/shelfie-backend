FactoryBot.define do
  factory :user do
    sequence(:clerk_user_id) { |n| "clerk_user_#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}name" }
    nickname { "テストユーザー" }
  end
end
