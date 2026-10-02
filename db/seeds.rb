# Idempotent: safe to run repeatedly with `bin/rails db:seed`.

providers = {
  alice: { name: "Alice Nguyen", email: "alice@example.com" },
  ben:   { name: "Ben Ortiz",    email: "ben@example.com" }
}.transform_values { |attrs| Provider.find_or_create_by!(email: attrs[:email]) { it.name = attrs[:name] } }

clients = {
  carol: { name: "Carol Diaz",  email: "carol@example.com" },
  dave:  { name: "Dave Kim",    email: "dave@example.com" },
  erin:  { name: "Erin Walsh",  email: "erin@example.com" },
  frank: { name: "Frank Moore", email: "frank@example.com" }
}.transform_values { |attrs| Client.find_or_create_by!(email: attrs[:email]) { it.name = attrs[:name] } }

# Carol is premium with Alice but basic with Ben: the plan lives on the relationship.
[
  [ :alice, :carol, "premium" ],
  [ :alice, :dave,  "basic" ],
  [ :alice, :frank, "basic" ],
  [ :ben,   :carol, "basic" ],
  [ :ben,   :erin,  "premium" ]
].each do |provider, client, plan|
  Subscription.find_or_create_by!(provider: providers[provider], client: clients[client]) { it.plan = plan }
end

# Frank never posts.
{
  carol: [ [ 1, "Slept 8 hours and went for a morning run." ],
           [ 4, "Meal-prepped lunches for the week." ],
           [ 9, "Tried the overnight oats recipe. Loved it." ] ],
  dave:  [ [ 2, "Skipped breakfast again, felt sluggish by noon." ],
           [ 12, "Stressful week at work, lots of takeout." ] ],
  erin:  [ [ 0, "Hit my water goal for the first time!" ],
           [ 6, "Started logging meals in the app." ] ]
}.each do |client, entries|
  next if clients[client].journal_entries.exists?

  entries.each do |days_ago, body|
    clients[client].journal_entries.create!(body: body, created_at: days_ago.days.ago)
  end
end

puts "Seeded #{Provider.count} providers, #{Client.count} clients, " \
     "#{Subscription.count} subscriptions, #{JournalEntry.count} journal entries."
