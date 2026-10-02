require "rails_helper"

RSpec.describe Provider do
  describe "validations" do
    it "is valid with a name and email" do
      expect(build(:provider)).to be_valid
    end

    it "requires a name" do
      provider = build(:provider, name: nil)

      expect(provider).not_to be_valid
      expect(provider.errors[:name]).to include("can't be blank")
    end

    it "requires an email" do
      provider = build(:provider, email: nil)

      expect(provider).not_to be_valid
      expect(provider.errors[:email]).to include("can't be blank")
    end

    it "requires a unique email" do
      existing = create(:provider)
      provider = build(:provider, email: existing.email)

      expect(provider).not_to be_valid
      expect(provider.errors[:email]).to include("has already been taken")
    end

    it "normalizes email to lowercase without surrounding whitespace" do
      provider = create(:provider, email: "  Mixed.Case@Example.COM ")

      expect(provider.email).to eq("mixed.case@example.com")
    end

    it "treats email uniqueness as case-insensitive" do
      existing = create(:provider)
      provider = build(:provider, email: existing.email.upcase)

      expect(provider).not_to be_valid
      expect(provider.errors[:email]).to include("has already been taken")
    end

    it "rejects a malformed email" do
      provider = build(:provider, email: "not-an-email")

      expect(provider).not_to be_valid
      expect(provider.errors[:email]).to include("is invalid")
    end
  end

  describe "database constraints" do
    it "rejects a missing name even when validations are skipped" do
      provider = build(:provider, name: nil)

      expect { provider.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a duplicate email even when validations are skipped" do
      existing = create(:provider)
      duplicate = build(:provider, email: existing.email)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#clients" do
    it "returns the provider's clients and no one else's" do
      provider = create(:provider)
      carol, dave = create_list(:client, 2)
      create(:subscription, provider:, client: carol)
      create(:subscription, provider:, client: dave)
      create(:subscription)

      expect(provider.clients).to contain_exactly(carol, dave)
    end
  end

  describe "#journal_entries" do
    it "returns entries across all of the provider's clients, newest first" do
      provider = create(:provider)
      carol, dave = create_list(:client, 2)
      create(:subscription, provider:, client: carol)
      create(:subscription, provider:, client: dave)
      old = create(:journal_entry, client: dave, created_at: 10.days.ago)
      recent = create(:journal_entry, client: carol, created_at: 1.day.ago)

      expect(provider.journal_entries.newest_first).to eq([ recent, old ])
    end

    it "excludes entries from clients of other providers" do
      provider = create(:provider)
      mine = create(:journal_entry, client: create(:subscription, provider:).client)
      create(:journal_entry, client: create(:subscription).client)

      expect(provider.journal_entries).to contain_exactly(mine)
    end

    it "loads the feed in a single query" do
      provider = create(:provider)
      create(:journal_entry, client: create(:subscription, provider:).client)

      expect(count_queries { provider.journal_entries.newest_first.to_a }).to eq(1)
    end
  end

  describe "#destroy" do
    it "destroys its subscriptions but not its clients" do
      provider = create(:provider)
      create_list(:subscription, 2, provider:)

      expect { provider.destroy }
        .to change(Subscription, :count).by(-2)
        .and not_change(Client, :count)
    end
  end

  def count_queries(&block)
    count = 0
    counter = ->(*, payload) { count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end
