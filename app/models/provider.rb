class Provider < ApplicationRecord
  has_many :subscriptions, dependent: :destroy
  has_many :clients, through: :subscriptions

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
