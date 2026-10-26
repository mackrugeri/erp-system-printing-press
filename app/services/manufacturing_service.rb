# app/services/manufacturing_service.rb
class ManufacturingService
  def self.produce(finished_item, qty_to_make, warehouse)
    ActiveRecord::Base.transaction do
      # 1. Create a Journal Entry to link physical & financial movement
      journal = JournalEntry.create!(
        date: Date.today,
        description: "Production: #{qty_to_make}x #{finished_item.name}",
        reference: "MFG-#{SecureRandom.hex(3).upcase}"
      )

      total_value_consumed = 0

      # 2. Consume Raw Materials
      finished_item.bom_items.each do |bom|
        material = Item.find(bom.material_id)
        usage_qty = bom.quantity * qty_to_make
        
        # Calculate value based on material cost price
        material_value = (material.cost_price || 0) * usage_qty
        total_value_consumed += material_value

        StockTransaction.create!(
          item: material,
          warehouse: warehouse,
          quantity: usage_qty, # Model auto-negates 'production_consumption'
          transaction_type: 'production_consumption',
          journal_entry: journal,
          notes: "Consumption for #{finished_item.name} run"
        )
      end

      # 3. Add the Finished Good to Stock
      StockTransaction.create!(
        item: finished_item,
        warehouse: warehouse,
        quantity: qty_to_make,
        transaction_type: 'production_output',
        journal_entry: journal,
        notes: "Manufactured output"
      )

      # 4. Accounting: Shift Value (Asset to Asset)
      # We assume standard account names here
      raw_materials_acc = Account.find_by!(name: "Raw Materials")
      finished_goods_acc = Account.find_by!(name: "Finished Goods")

      # DEBIT Finished Goods (Increase Asset)
      journal.ledger_entries.create!(account_id: finished_goods_acc.id, debit: total_value_consumed, credit: 0)
      # CREDIT Raw Materials (Decrease Asset)
      journal.ledger_entries.create!(account_id: raw_materials_acc.id, debit: 0, credit: total_value_consumed)
      
      journal # Return the journal object
    end
  rescue ActiveRecord::RecordInvalid => e
    raise "Production Failed: #{e.message}"
  end
end