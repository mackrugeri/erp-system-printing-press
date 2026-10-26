class CreateWarehouses < ActiveRecord::Migration[8.1]
  def change
    create_table :warehouses do |t|
      t.string :name, null: false
      t.string :location
      t.timestamps
    end
    
    # Add warehouse reference to stock transactions
    add_reference :stock_transactions, :warehouse, foreign_key: true
  end
end
