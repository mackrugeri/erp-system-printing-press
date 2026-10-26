class CreatePurchaseBills < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_bills do |t|
      t.references :contact, null: false, foreign_key: true # The Vendor
      t.string :bill_number
      t.date :date
      t.decimal :total_amount, precision: 15, scale: 2
      t.string :status
      t.references :journal_entry, foreign_key: true
      t.timestamps
    end
  end
end
