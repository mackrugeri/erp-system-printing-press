class Invoice < ApplicationRecord
  # --- Associations ---
  belongs_to :contact
  belongs_to :warehouse
  belongs_to :journal_entry, optional: true
  has_many :invoice_items, dependent: :destroy
  
  # --- Nested Attributes ---
  # allow_destroy: true enables the delete functionality from the form
  # reject_if ensures we don't save empty rows that would cause validation errors
  accepts_nested_attributes_for :invoice_items, 
                                allow_destroy: true, 
                                reject_if: proc { |att| att['item_id'].blank? }

  # --- Validations ---
  validates :date, :contact_id, :warehouse_id, presence: true
  validates :invoice_number, uniqueness: true, allow_blank: true

  # --- Callbacks ---
  before_create :set_invoice_number
  before_save :calculate_total

  # --- Core Logic: Posting to Ledger & Stock ---
  def post_to_ledger_and_stock!(sales_account_id)
    # 1. Guard Clauses & Recalculation
    
    self.calculate_total
    raise "Cannot post: Invoice total is zero." if self.total_amount <= 0
    raise "Customer must have a linked Accounting Account." if self.contact.account_id.nil?

    transaction do
      # 2. Initialize the Journal Entry (Do NOT use .create! yet)
      journal = JournalEntry.new(
        date: self.date,
        description: "Sales Invoice: #{self.invoice_number}",
        reference: self.invoice_number
      )

      # 3. Build Main Sales Entries
      # DEBIT: Accounts Receivable (Customer)
      journal.ledger_entries.build(account_id: self.contact.account_id, debit: self.total_amount, credit: 0)
      # CREDIT: Sales Income
      journal.ledger_entries.build(account_id: sales_account_id, debit: 0, credit: self.total_amount)

      total_cogs = 0
      
      # 4. Inventory & COGS Loop
      self.invoice_items.each do |line|
        # Reduce Stock
        StockTransaction.create!(
          item: line.item,
          warehouse_id: self.warehouse_id,
          quantity: -line.quantity, 
          transaction_type: 'sale',
          notes: "Sale - Invoice #{self.invoice_number}"
        )

        item_cost = line.item.standard_cost || 0
        total_cogs += (line.quantity * item_cost)
      end

      # 5. Build COGS Entries (Built into the SAME journal entry)
      # if total_cogs > 0
      #   cogs_account = Account.find_by!(name: "Cost of Goods Sold")
      #   inventory_account = Account.find_by!(name: "Finished Goods Inventory")

      #   # DEBIT: COGS
      #   journal.ledger_entries.build(account: cogs_account, debit: total_cogs, credit: 0)
      #   # CREDIT: Inventory
      #   journal.ledger_entries.build(account: inventory_account, debit: 0, credit: total_cogs)
      # end

      # 6. Save everything. This triggers the 'must_be_balanced' validation.
      # Since all rows are built, the total_debit will equal total_credit.
      journal.save!

      # 7. Finalize Invoice
      self.update!(journal_entry: journal, status: 'Posted')
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Invoice Posting Failed: #{e.record.errors.full_messages.join(', ')}"
    raise e
  end

  # --- Helper Methods ---

  def calculate_total
    # Reject items marked for destruction so the total updates correctly when a row is deleted
    self.total_amount = invoice_items.reject(&:marked_for_destruction?).sum do |item| 
      (item.quantity || 0) * (item.unit_price || 0) 
    end
  end

  private

  def set_invoice_number
    # Generates a unique SALE number if one doesn't exist
    return if invoice_number.present?
    self.invoice_number = "SALE-#{SecureRandom.hex(4).upcase}"
  end
end