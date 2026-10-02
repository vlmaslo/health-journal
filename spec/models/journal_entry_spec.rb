require "rails_helper"

RSpec.describe JournalEntry do
  describe "validations" do
    it "is valid with a client and body" do
      expect(build(:journal_entry)).to be_valid
    end

    it "requires a body" do
      entry = build(:journal_entry, body: nil)

      expect(entry).not_to be_valid
      expect(entry.errors[:body]).to include("can't be blank")
    end

    it "requires a client without raising" do
      entry = build(:journal_entry, client: nil)

      expect(entry).not_to be_valid
      expect(entry.errors[:client]).to include("must exist")
    end
  end

  describe "database constraints" do
    it "rejects a missing body even when validations are skipped" do
      entry = build(:journal_entry, client: create(:client), body: nil)

      expect { entry.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a client that does not exist" do
      entry = build(:journal_entry, client: nil, client_id: 0)

      expect { entry.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end
end
