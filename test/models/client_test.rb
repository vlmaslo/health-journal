require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "valid with name and email" do
    assert Client.new(name: "New Client", email: "new@example.com").valid?
  end

  test "requires a name" do
    client = Client.new(email: "new@example.com")
    assert_not client.valid?
    assert_includes client.errors[:name], "can't be blank"
  end

  test "requires an email" do
    client = Client.new(name: "New Client")
    assert_not client.valid?
    assert_includes client.errors[:email], "can't be blank"
  end

  test "requires a unique email" do
    client = Client.new(name: "Impostor", email: clients(:carol).email)
    assert_not client.valid?
    assert_includes client.errors[:email], "has already been taken"
  end

  test "normalizes email to lowercase without surrounding whitespace" do
    client = Client.create!(name: "Mixed", email: "  Mixed.Case@Example.COM ")
    assert_equal "mixed.case@example.com", client.email
  end

  test "email uniqueness is case-insensitive" do
    client = Client.new(name: "Impostor", email: clients(:carol).email.upcase)
    assert_not client.valid?
    assert_includes client.errors[:email], "has already been taken"
  end

  test "rejects a malformed email" do
    client = Client.new(name: "Bad", email: "not-an-email")
    assert_not client.valid?
    assert_includes client.errors[:email], "is invalid"
  end

  test "database rejects a missing name even when validations are skipped" do
    client = Client.new(name: nil, email: "new@example.com")
    assert_raises(ActiveRecord::NotNullViolation) { client.save!(validate: false) }
  end

  test "database rejects duplicate email even when validations are skipped" do
    duplicate = Client.new(name: "Impostor", email: clients(:carol).email)
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "has providers through subscriptions" do
    assert_equal [ providers(:alice), providers(:bob) ].sort, clients(:carol).providers.sort
  end

  test "journal entries newest first" do
    carol = clients(:carol)
    older = carol.journal_entries.create!(body: "Older", created_at: 3.days.ago)

    assert_equal [ journal_entries(:carol_recent), older ], carol.journal_entries.newest_first.to_a
  end

  test "journal entries with the same timestamp are ordered by id" do
    carol = clients(:carol)
    at = 2.days.ago
    first = carol.journal_entries.create!(body: "First", created_at: at)
    second = carol.journal_entries.create!(body: "Second", created_at: at)

    assert_equal [ journal_entries(:carol_recent), second, first ], carol.journal_entries.newest_first.to_a
  end

  test "cannot be destroyed while it has journal entries" do
    carol = clients(:carol)

    assert_no_difference [ -> { Client.count }, -> { JournalEntry.count }, -> { Subscription.count } ] do
      assert_not carol.destroy
    end
    assert_includes carol.errors[:base], "Cannot delete record because dependent journal entries exist"
  end

  test "can be destroyed without journal entries, taking its subscriptions but not its providers" do
    erin = clients(:erin)

    assert_difference -> { Subscription.count }, -1 do
      assert_no_difference -> { Provider.count } do
        assert erin.destroy
      end
    end
    assert_not Client.exists?(erin.id)
  end
end
