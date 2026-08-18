FactoryBot.define do
  factory :user_identity do
    user
    provider { "google" }
    sequence(:provider_uid) { |n| "provider_uid_#{n}" }
    sequence(:email) { |n| "identity#{n}@example.com" }
  end
end
