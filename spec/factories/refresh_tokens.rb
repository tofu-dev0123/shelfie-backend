FactoryBot.define do
  factory :refresh_token do
    association :user
    sequence(:token) { |n| "refresh_token_#{n}" }
    expires_at { 30.days.from_now }
  end
end
