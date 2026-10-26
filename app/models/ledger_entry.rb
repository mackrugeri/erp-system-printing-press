class LedgerEntry < ApplicationRecord
  belongs_to :journal_entry
  belongs_to :account
  
  attr_accessor :debit_account_id, :credit_account_id, :amount
  
  validates :debit, :credit, presence: true, numericality: { greater_than_or_equal_to: 0 }
end