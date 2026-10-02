require "rails_helper"

RSpec.describe Subscription do
  describe "validations" do
    it "is valid with a provider, client, and plan" do
      expect(build(:subscription, plan: "premium")).to be_valid
    end

    it "defaults to the basic plan" do
      expect(described_class.new.plan).to eq("basic")
    end

    it "requires a provider and a client" do
      subscription = described_class.new

      expect(subscription).not_to be_valid
      expect(subscription.errors[:provider]).to include("must exist")
      expect(subscription.errors[:client]).to include("must exist")
    end

    it "rejects an unknown plan" do
      subscription = build(:subscription, plan: "gold")

      expect(subscription).not_to be_valid
      expect(subscription.errors[:plan]).to include("is not included in the list")
    end

    it "allows a client to subscribe to the same provider only once" do
      existing = create(:subscription)
      duplicate = build(:subscription, provider: existing.provider, client: existing.client)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:client_id]).to include("has already been taken")
    end

    it "lets a client hold a different plan with each provider" do
      client = create(:client)
      with_alice = create(:subscription, client:, plan: "premium")
      with_bob = create(:subscription, client:, plan: "basic")

      expect(client.subscriptions.find_by(provider: with_alice.provider)).to be_premium
      expect(client.subscriptions.find_by(provider: with_bob.provider)).to be_basic
    end
  end

  describe "database constraints" do
    it "rejects an unknown plan even when validations are skipped" do
      subscription = build(:subscription, plan: "gold")

      expect { subscription.save!(validate: false) }.to raise_error(ActiveRecord::CheckViolation)
    end

    it "rejects a missing plan even when validations are skipped" do
      subscription = build(:subscription, plan: nil)

      expect { subscription.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a provider that does not exist" do
      subscription = build(:subscription, provider: nil, provider_id: 0)

      expect { subscription.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "rejects a duplicate subscription even when validations are skipped" do
      existing = create(:subscription)
      duplicate = build(:subscription, provider: existing.provider, client: existing.client)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
