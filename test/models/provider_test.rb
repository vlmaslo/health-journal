require "test_helper"

class ProviderTest < ActiveSupport::TestCase
  test "valid with name and email" do
    assert Provider.new(name: "New Provider", email: "new@example.com").valid?
  end

  test "requires a name" do
    provider = Provider.new(email: "new@example.com")
    assert_not provider.valid?
    assert_includes provider.errors[:name], "can't be blank"
  end

  test "requires an email" do
    provider = Provider.new(name: "New Provider")
    assert_not provider.valid?
    assert_includes provider.errors[:email], "can't be blank"
  end

  test "requires a unique email" do
    provider = Provider.new(name: "Impostor", email: providers(:alice).email)
    assert_not provider.valid?
    assert_includes provider.errors[:email], "has already been taken"
  end

  test "normalizes email to lowercase without surrounding whitespace" do
    provider = Provider.create!(name: "Mixed", email: "  Mixed.Case@Example.COM ")
    assert_equal "mixed.case@example.com", provider.email
  end

  test "email uniqueness is case-insensitive" do
    provider = Provider.new(name: "Impostor", email: providers(:alice).email.upcase)
    assert_not provider.valid?
    assert_includes provider.errors[:email], "has already been taken"
  end

  test "rejects a malformed email" do
    provider = Provider.new(name: "Bad", email: "not-an-email")
    assert_not provider.valid?
    assert_includes provider.errors[:email], "is invalid"
  end

  test "database rejects a missing name even when validations are skipped" do
    provider = Provider.new(name: nil, email: "new@example.com")
    assert_raises(ActiveRecord::NotNullViolation) { provider.save!(validate: false) }
  end

  test "database rejects duplicate email even when validations are skipped" do
    duplicate = Provider.new(name: "Impostor", email: providers(:alice).email)
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "has clients through subscriptions" do
    assert_equal [ clients(:carol), clients(:dave) ].sort, providers(:alice).clients.sort
  end

  test "destroying a provider destroys its subscriptions but not its clients" do
    assert_difference -> { Subscription.count }, -2 do
      assert_no_difference -> { Client.count } do
        providers(:alice).destroy
      end
    end
  end
end
