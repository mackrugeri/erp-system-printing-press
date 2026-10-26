class CreateCashTallies < ActiveRecord::Migration[7.0]
  def change
    create_table :cash_tallies do |t|
      t.references :account, null: false, foreign_key: true # <--- Removed the 's' and '_id'
      t.decimal :system_amount, precision: 15, scale: 2
      t.decimal :physical_amount, precision: 15, scale: 2
      t.decimal :difference, precision: 15, scale: 2
      t.text :note

      t.timestamps
    end
  end
end