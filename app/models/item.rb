# app/models/item.rb
class Item < ApplicationRecord
  belongs_to :item_category
  has_many :stock_transactions, dependent: :destroy
  
  # Manufacturing Relationships
  # bom_items links this item to its "recipe" ingredients
  has_many :bom_items, dependent: :destroy
  # If this item is used as a material for other products
  has_many :used_in_boms, class_name: 'BomItem', foreign_key: 'material_id'

  validates :sku, presence: true, uniqueness: true
  validates :name, presence: true

  # Helper to identify if an item can be manufactured
  def manufactured?
    bom_items.exists?
  end

  def current_stock
    stock_transactions.sum(:quantity)
  end

  # Helper for warehouse-specific stock
  def stock_in_warehouse(warehouse_id)
    stock_transactions.where(warehouse_id: warehouse_id).sum(:quantity)
  end

  def total_stock
    stock_transactions.sum(:quantity)
  end


  def inventory_value
    current_stock * (cost_price || 0)
  end
end