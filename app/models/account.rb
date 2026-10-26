class Account < ApplicationRecord
  has_many :ledger_entries
  belongs_to :parent, class_name: "Account", optional: true
  has_many :sub_accounts, class_name: "Account", foreign_key: "parent_id"

  TYPES = %w[Asset Liability Income Equity Expense Inward-Expense Outward-Expense].freeze
  validates :account_type, inclusion: { in: TYPES }
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  def debit_normal?
    %w[Asset Expense].include?(account_type)
  end

  def balance
    calculate_balance(ledger_entries)
  end

  def balance_for_range(start_date, end_date)
    entries = ledger_entries.joins(:journal_entry).where(journal_entries: { date: start_date..end_date })
    entries.any? ? calculate_balance(entries) : 0
  end

  private

  def calculate_balance(entries_scope)
    debits = entries_scope.sum(:debit) || 0
    credits = entries_scope.sum(:credit) || 0
    
    movement = debit_normal? ? (debits - credits) : (credits - debits)
    # Ensure opening_balance is accounted for
    (opening_balance || 0) + movement
  end
end