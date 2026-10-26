class CreateStockTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_transactions do |t|
      t.references :item, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2 # Positive for IN, Negative for OUT
      t.string :transaction_type # Purchase, Sale, Adjustment, Production
      t.references :journal_entry, foreign_key: true # Audit trail to Accounting

      t.timestamps
    end
  end
end
