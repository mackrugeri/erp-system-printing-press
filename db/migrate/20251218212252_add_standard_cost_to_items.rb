class AddStandardCostToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :standard_cost, :decimal
  end
end
