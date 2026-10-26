class AccountingService
  # POST SALES INVOICE
  # Logic: Debit Customer (AR), Credit Sales Revenue
  # Optional: Debit COGS, Credit Inventory (if tracking real-time inventory)
  def self.post_invoice(invoice)
    JournalEntry.transaction do
      journal = JournalEntry.create!(
        date: invoice.date,
        description: "Sales Invoice: #{invoice.invoice_number}",
        reference: invoice.invoice_number,
        entry_type: 'Sale'
      )

      # 1. Debit Customer (Accounts Receivable)
      # Increase Asset
      LedgerEntry.create!(
        journal_entry: journal,
        account_id: invoice.contact.account_id,
        debit: invoice.total_amount,
        credit: 0
      )

      # 2. Credit Sales Revenue
      # Increase Income
      sales_account = Account.find_by!(name: "Sales Revenue")
      LedgerEntry.create!(
        journal_entry: journal,
        account_id: sales_account.id,
        debit: 0,
        credit: invoice.total_amount
      )

      # 3. Handle Inventory & COGS (Manufacturing Logic)
      invoice.invoice_items.each do |line|
        cost_value = line.item.cost_price * line.quantity
        
        # Record Stock Movement
        StockTransaction.create!(
          item: line.item,
          quantity: -line.quantity, # Negative for OUT
          transaction_type: "Sale",
          journal_entry: journal
        )
      end

      invoice.update!(journal_entry: journal, status: "Posted")
    end
  end

  # POST PURCHASE BILL
  # Logic: Debit Inventory Asset, Credit Vendor (AP)
  def self.post_purchase(bill)
    JournalEntry.transaction do
      journal = JournalEntry.create!(
        date: bill.date,
        description: "Purchase Bill: #{bill.bill_number}",
        reference: bill.bill_number,
        entry_type: 'Purchase'
      )

      # 1. Debit Inventory Asset
      # Increase Asset
      inventory_account = Account.find_by!(name: "Inventory Asset")
      LedgerEntry.create!(
        journal_entry: journal,
        account_id: inventory_account.id,
        debit: bill.total_amount,
        credit: 0
      )

      # 2. Credit Vendor (Accounts Payable)
      # Increase Liability
      LedgerEntry.create!(
        journal_entry: journal,
        account_id: bill.contact.account_id,
        debit: 0,
        credit: bill.total_amount
      )

      # 3. Increase Stock Quantity
      bill.purchase_bill_items.each do |line|
        StockTransaction.create!(
          item: line.item,
          quantity: line.quantity, # Positive for IN
          transaction_type: "Purchase",
          journal_entry: journal
        )
      end

      bill.update!(journal_entry: journal, status: "Posted")
    end
  end

  # RECORD PAYMENT
  # Logic: Debit Cash/Bank, Credit Customer (AR)
  def self.record_payment(contact, amount, method_account_id)
    JournalEntry.transaction do
      journal = JournalEntry.create!(
        date: Date.today,
        description: "Payment Received from #{contact.name}",
        entry_type: 'Payment'
      )

      # Debit Cash or Bank (Asset Increase)
      LedgerEntry.create!(
        journal_entry: journal,
        account_id: method_account_id,
        debit: amount,
        credit: 0
      )

      # Credit Customer Account (Asset Decrease)
      LedgerEntry.create!(
        journal_entry: journal,
        account_id: contact.account_id,
        debit: 0,
        credit: amount
      )
    end
  end
end