FactoryBot.define do
  factory :provider do
    sequence(:name) { |n| "Provider #{n}" }
    sequence(:email) { |n| "provider#{n}@example.com" }
  end
end
