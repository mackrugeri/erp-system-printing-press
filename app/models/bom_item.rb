# app/models/bom_item.rb
class BomItem < ApplicationRecord
  belongs_to :item # The parent/Finished Good
  belongs_to :material, class_name: 'Item' # The ingredient/Raw Material

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :material_id, presence: true
end