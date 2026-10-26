class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.string :sku, index: { unique: true }
      t.string :item_type # Raw Material, WIP, Finished Good
      t.decimal :unit_price, precision: 15, scale: 2
      t.decimal :cost_price, precision: 15, scale: 2
      t.integer :reorder_level, default: 0

      t.timestamps
    end
  end
end
