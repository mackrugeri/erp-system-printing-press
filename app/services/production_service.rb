# app/services/production_service.rb
class ProductionService
  def self.produce(finished_item, quantity, warehouse)
    ActiveRecord::Base.transaction do
      # 1. Deduct Raw Materials based on BOM
      finished_item.bom_items.each do |bom|
        required_qty = bom.quantity * quantity
        
        # Check stock availability
        current_stock = bom.raw_material.current_stock_in(warehouse)
        raise "Insufficient #{bom.raw_material.name}" if current_stock < required_qty

        StockTransaction.create!(
          item: bom.raw_material,
          warehouse: warehouse,
          quantity: -required_qty,
          transaction_type: 'production_consumption'
        )
      end

      # 2. Add Finished Good
      StockTransaction.create!(
        item: finished_item,
        warehouse: warehouse,
        quantity: quantity,
        transaction_type: 'production_output'
      )
    end
  end
end