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
end
