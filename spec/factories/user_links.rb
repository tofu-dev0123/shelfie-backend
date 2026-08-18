FactoryBot.define do
  factory :user_link do
    association :user
    url { "https://github.com/komusan" }
  end
end
