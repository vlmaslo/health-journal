require "test_helper"

class JournalEntryTest < ActiveSupport::TestCase
  test "valid with a client and body" do
    assert JournalEntry.new(client: clients(:carol), body: "Ate a salad.").valid?
  end

  test "requires a body" do
    entry = JournalEntry.new(client: clients(:carol))
    assert_not entry.valid?
    assert_includes entry.errors[:body], "can't be blank"
  end

  test "requires a client without raising" do
    entry = JournalEntry.new(body: "Orphan entry")
    assert_not entry.valid?
    assert_includes entry.errors[:client], "must exist"
  end

  test "database rejects a missing body even when validations are skipped" do
    entry = JournalEntry.new(client: clients(:carol), body: nil)
    assert_raises(ActiveRecord::NotNullViolation) { entry.save!(validate: false) }
  end

  test "database rejects an entry for a client that does not exist" do
    entry = JournalEntry.new(client_id: 0, body: "Orphan entry")
    assert_raises(ActiveRecord::InvalidForeignKey) { entry.save!(validate: false) }
  end
end
