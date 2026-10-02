class Provider < ApplicationRecord
  has_many :subscriptions, dependent: :destroy
  has_many :clients, through: :subscriptions
  has_many :journal_entries, through: :clients

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
