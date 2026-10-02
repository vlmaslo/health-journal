require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  test "valid with a provider, client, and plan" do
    assert Subscription.new(provider: providers(:bob), client: clients(:dave), plan: "premium").valid?
  end

  test "defaults to the basic plan" do
    assert_equal "basic", Subscription.new.plan
  end

  test "requires a provider and a client" do
    subscription = Subscription.new
    assert_not subscription.valid?
    assert_includes subscription.errors[:provider], "must exist"
    assert_includes subscription.errors[:client], "must exist"
  end

  test "rejects an unknown plan" do
    subscription = Subscription.new(provider: providers(:bob), client: clients(:dave), plan: "gold")
    assert_not subscription.valid?
    assert_includes subscription.errors[:plan], "is not included in the list"
  end

  test "database rejects an unknown plan even when validations are skipped" do
    subscription = Subscription.new(provider: providers(:bob), client: clients(:dave), plan: "gold")
    assert_raises(ActiveRecord::CheckViolation) { subscription.save!(validate: false) }
  end

  test "database rejects a missing plan even when validations are skipped" do
    subscription = Subscription.new(provider: providers(:bob), client: clients(:dave), plan: nil)
    assert_raises(ActiveRecord::NotNullViolation) { subscription.save!(validate: false) }
  end

  test "database rejects a subscription to a provider that does not exist" do
    subscription = Subscription.new(provider_id: 0, client: clients(:dave))
    assert_raises(ActiveRecord::InvalidForeignKey) { subscription.save!(validate: false) }
  end

  test "a client can subscribe to the same provider only once" do
    duplicate = Subscription.new(provider: providers(:alice), client: clients(:carol))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:client_id], "has already been taken"
  end

  test "database rejects a duplicate subscription even when validations are skipped" do
    duplicate = Subscription.new(provider: providers(:alice), client: clients(:carol))
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "a client can hold a different plan with each provider" do
    carol = clients(:carol)
    assert_equal "premium", carol.subscriptions.find_by(provider: providers(:alice)).plan
    assert_equal "basic", carol.subscriptions.find_by(provider: providers(:bob)).plan
  end
end
