class JournalEntry < ApplicationRecord
  has_many :ledger_entries, dependent: :destroy
  
  # Logic: reject_if ensures that if you provide 5 rows but only use 2, 
  # the 3 empty ones don't trigger "Account must exist" errors.
  accepts_nested_attributes_for :ledger_entries, allow_destroy: true,
    reject_if: proc { |att| att['account_id'].blank? && att['debit'].to_f == 0 && att['credit'].to_f == 0 }


  validates :date, :description, presence: true
  validates :reference, presence: true, uniqueness: true
  validate :must_be_balanced

  before_validation :generate_voucher_number, on: :create

  private

  def generate_voucher_number
    return if reference.present?

    prefix = "JE-"
    start_num = 1000

    # PostgreSQL specific: We use SUBSTRING with 'FROM' and cast to INTEGER
    # This finds the last JE- number in the database
    last_entry = JournalEntry.where("reference LIKE ?", "#{prefix}%")
                             .order(Arel.sql("CAST(SUBSTRING(reference FROM 4) AS INTEGER) DESC"))
                             .first

    if last_entry.present?
      # Extract the number part from the string (e.g., "JE-1005" -> 1005)
      last_num = last_entry.reference.split("-").last.to_i
      self.reference = "#{prefix}#{last_num + 1}"
    else
      # First entry in the system
      self.reference = "#{prefix}#{start_num}"
    end
  end

  def must_be_balanced
    # .to_f is critical here to prevent "nil can't be coerced into Float" errors
    total_debit = ledger_entries.sum { |l| l.debit.to_f }.round(2)
    total_credit = ledger_entries.sum { |l| l.credit.to_f }.round(2)
    
    if total_debit != total_credit
      errors.add(:base, "The journal entry is unbalanced. Total Debits ($#{total_debit}) must equal Total Credits ($#{total_credit}).")
    end
    
    if total_debit == 0 && total_credit == 0
      errors.add(:base, "Journal entry cannot be zero.")
    end
  end
end