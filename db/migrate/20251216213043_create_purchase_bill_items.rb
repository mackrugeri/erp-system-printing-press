class CreatePurchaseBillItems < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_bill_items do |t|
      t.references :purchase_bill, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2
      t.decimal :unit_price, precision: 15, scale: 2
      t.timestamps
    end
  end
end
