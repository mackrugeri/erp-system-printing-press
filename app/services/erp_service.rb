class ErpService
  # Call this when a Purchase Bill is saved
  def self.post_purchase_bill(bill)
    ActiveRecord::Base.transaction do
      # 1. Update Stock
      bill.purchase_bill_items.each do |line|
        StockTransaction.create!(
          item: line.item,
          warehouse_id: Warehouse.first.id, # Adjust as needed
          quantity: line.quantity,
          transaction_type: 'purchase',
          notes: "Bill ##{bill.bill_number}"
        )
      end

      # 2. Post to Ledger
      entry = JournalEntry.create!(
        date: bill.date,
        reference: bill.bill_number,
        description: "Purchase: #{bill.contact.name}"
      )

      # Debit Inventory Asset, Credit Accounts Payable
      entry.ledger_entries.create!(account: Account.find_by(name: "Inventory Asset"), debit: bill.total_amount, credit: 0)
      entry.ledger_entries.create!(account: Account.find_by(name: "Accounts Payable"), debit: 0, credit: bill.total_amount)

      bill.update!(status: 'Posted', journal_entry: entry)
    end
  end

  # Call this for Manufacturing
  def self.produce_item(finished_item, qty, warehouse)
    ActiveRecord::Base.transaction do
      finished_item.bom_items.each do |bom|
        material = Item.find(bom.material_id)
        StockTransaction.create!(item: material, warehouse: warehouse, quantity: -(bom.quantity * qty), transaction_type: 'production')
      end
      StockTransaction.create!(item: finished_item, warehouse: warehouse, quantity: qty, transaction_type: 'production')
    end
  end
end