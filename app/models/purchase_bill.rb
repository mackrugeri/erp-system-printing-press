class PurchaseBill < ApplicationRecord
  belongs_to :contact
  belongs_to :warehouse # Added association
  belongs_to :journal_entry, optional: true
  has_many :purchase_bill_items, dependent: :destroy
  
  accepts_nested_attributes_for :purchase_bill_items, allow_destroy: true, 
                                reject_if: proc { |att| att['item_id'].blank? }

  validates :bill_number, presence: true, uniqueness: true
  validates :date, :contact_id, :warehouse_id, presence: true

  before_validation :ensure_unique_bill_number, on: :create
  before_save :calculate_total

  def calculate_total
    self.total_amount = purchase_bill_items.reject(&:marked_for_destruction?).sum do |i| 
      (i.quantity || 0) * (i.unit_price || 0) 
    end
  end

  # ERP Core Method: Post to Accounting & Stock
  def post_to_ledger_and_inventory!(inventory_account_id)
    # 1. Recalculate to ensure we have a value to send to the Journal
    self.calculate_total
    
    if self.total_amount <= 0
      raise "Cannot post: Bill total is zero."
    end

    transaction do
      # 2. Initialize the Journal Entry without saving yet
      journal = JournalEntry.new(
        date: self.date,
        description: "Purchase Bill: #{self.bill_number}",
        reference: self.bill_number
      )

      # 3. Build the Ledger Entries (Debits/Credits)
      # This populates the ledger_entries collection so 'must_be_balanced' can see them
      journal.ledger_entries.build(
        account_id: inventory_account_id, 
        debit: self.total_amount, 
        credit: 0
      )
      
      journal.ledger_entries.build(
        account_id: self.contact.account_id, 
        debit: 0, 
        credit: self.total_amount
      )

      # 4. Save the journal. This triggers 'must_be_balanced' in JournalEntry
      # If the sums match and aren't zero, it will succeed.
      journal.save!
      
      # 5. Stock Increase
      self.purchase_bill_items.each do |line|
        StockTransaction.create!(
          item_id: line.item_id,
          warehouse_id: self.warehouse_id,
          quantity: line.quantity,
          transaction_type: 'Purchase',
          notes: "Bill #{self.bill_number}"
        )
      end
      
      # 6. Finalize the link
      self.update!(journal_entry: journal, status: 'Posted')
    end
  end

  private

  def ensure_unique_bill_number
    if self.bill_number.blank? || PurchaseBill.exists?(bill_number: self.bill_number)
      loop do
        new_number = "PURCHASE-#{SecureRandom.hex(3).upcase}"
        break self.bill_number = new_number unless PurchaseBill.exists?(bill_number: new_number)
      end
    end
  end
end