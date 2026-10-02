FactoryBot.define do
  factory :journal_entry do
    client
    body { "Slept well and went for a run." }
  end
end
