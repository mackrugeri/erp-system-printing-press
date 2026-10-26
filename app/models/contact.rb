class Contact < ApplicationRecord
  belongs_to :account # The specific AR/AP account in the Ledger
  
  validates :name, :contact_type, presence: true
  validates :contact_type, inclusion: { in: %w[Customer Vendor] }
end