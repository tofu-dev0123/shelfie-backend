FactoryBot.define do
  factory :want_to_read do
    association :user
    association :book
  end
end
