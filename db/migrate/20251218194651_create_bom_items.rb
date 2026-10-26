class CreateBomItems < ActiveRecord::Migration[7.0]
  def change
    create_table :bom_items do |t|
      t.references :item, null: false, foreign_key: true # The Finished Good
      t.integer :material_id, null: false               # The Raw Material ID
      t.decimal :quantity, precision: 10, scale: 2      # Qty needed for 1 unit
      t.timestamps
    end
    add_index :bom_items, :material_id
  end
end