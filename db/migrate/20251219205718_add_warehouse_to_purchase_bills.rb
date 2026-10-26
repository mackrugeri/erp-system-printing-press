class AddWarehouseToPurchaseBills < ActiveRecord::Migration[8.1]
  def change
    add_reference :purchase_bills, :warehouse, null: true, foreign_key: true
  end
end
