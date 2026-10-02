require "rails_helper"

RSpec.describe Client do
  describe "validations" do
    it "is valid with a name and email" do
      expect(build(:client)).to be_valid
    end

    it "requires a name" do
      client = build(:client, name: nil)

      expect(client).not_to be_valid
      expect(client.errors[:name]).to include("can't be blank")
    end

    it "requires an email" do
      client = build(:client, email: nil)

      expect(client).not_to be_valid
      expect(client.errors[:email]).to include("can't be blank")
    end

    it "requires a unique email" do
      existing = create(:client)
      client = build(:client, email: existing.email)

      expect(client).not_to be_valid
      expect(client.errors[:email]).to include("has already been taken")
    end

    it "normalizes email to lowercase without surrounding whitespace" do
      client = create(:client, email: "  Mixed.Case@Example.COM ")

      expect(client.email).to eq("mixed.case@example.com")
    end

    it "treats email uniqueness as case-insensitive" do
      existing = create(:client)
      client = build(:client, email: existing.email.upcase)

      expect(client).not_to be_valid
      expect(client.errors[:email]).to include("has already been taken")
    end

    it "rejects a malformed email" do
      client = build(:client, email: "not-an-email")

      expect(client).not_to be_valid
      expect(client.errors[:email]).to include("is invalid")
    end
  end

  describe "database constraints" do
    it "rejects a missing name even when validations are skipped" do
      client = build(:client, name: nil)

      expect { client.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a duplicate email even when validations are skipped" do
      existing = create(:client)
      duplicate = build(:client, email: existing.email)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#providers" do
    it "returns the client's providers and no one else's" do
      client = create(:client)
      alice, bob = create_list(:provider, 2)
      create(:subscription, provider: alice, client:)
      create(:subscription, provider: bob, client:)
      create(:subscription)

      expect(client.providers).to contain_exactly(alice, bob)
    end
  end

  describe "#journal_entries" do
    it "can be read newest first" do
      client = create(:client)
      older = create(:journal_entry, client:, created_at: 3.days.ago)
      recent = create(:journal_entry, client:, created_at: 1.day.ago)

      expect(client.journal_entries.newest_first).to eq([ recent, older ])
    end

    it "orders entries with the same timestamp by id" do
      client = create(:client)
      at = 2.days.ago
      first = create(:journal_entry, client:, created_at: at)
      second = create(:journal_entry, client:, created_at: at)

      expect(client.journal_entries.newest_first).to eq([ second, first ])
    end
  end

  describe "#destroy" do
    it "is refused while the client has journal entries, and deletes nothing" do
      client = create(:subscription).client
      create(:journal_entry, client:)

      expect { client.destroy }
        .to not_change(Client, :count)
        .and not_change(JournalEntry, :count)
        .and not_change(Subscription, :count)
      expect(client.errors[:base]).to include("Cannot delete record because dependent journal entries exist")
    end

    it "succeeds without journal entries, taking its subscriptions but not its providers" do
      client = create(:subscription).client

      expect { client.destroy }
        .to change(Subscription, :count).by(-1)
        .and not_change(Provider, :count)
      expect(Client.exists?(client.id)).to be(false)
    end
  end
end
