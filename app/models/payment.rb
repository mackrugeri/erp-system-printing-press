# app/models/payment.rb
class Payment < ApplicationRecord
  belongs_to :contact
  belongs_to :account
  belongs_to :journal_entry, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true
  validates :payment_method, presence: true

  # We use before_save so that the amount is already validated
  before_save :generate_journal_entry, if: :new_record?

  private

  def generate_journal_entry
    return if amount.to_f <= 0

    Payment.transaction do
      # Create the parent Journal Entry first
      journal = JournalEntry.new(
        date: payment_date,
        description: "Payment: #{contact.name} [#{payment_method}]",
        reference: "PAY-#{SecureRandom.hex(3).upcase}"
      )

      if contact.contact_type == 'Customer'
        # Customer pays us: Increase Cash (Debit), Decrease Receivable (Credit)
        journal.ledger_entries.build(account: account, debit: amount, credit: 0)
        journal.ledger_entries.build(account: contact.account, debit: 0, credit: amount)
      else
        # We pay Vendor: Decrease Payable (Debit), Decrease Cash (Credit)
        journal.ledger_entries.build(account: contact.account, debit: amount, credit: 0)
        journal.ledger_entries.build(account: account, debit: 0, credit: amount)
      end

      # Attempt to save the journal. 
      # Using journal.save! will trigger validations in JournalEntry
      if journal.save
        self.journal_entry = journal
      else
        errors.add(:base, "Journal Validation Error: #{journal.errors.full_messages.join(', ')}")
        throw(:abort)
      end
    end
  end
end