class CreateItemCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :item_categories do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
    
    # Add category reference to items
    add_reference :items, :item_category, foreign_key: true
  end
end
