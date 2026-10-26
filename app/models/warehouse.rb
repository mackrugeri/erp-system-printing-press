class Warehouse < ApplicationRecord
  has_many :stock_transactions
  # This allows you to see all unique items that have ever entered this warehouse
  has_many :items, -> { distinct }, through: :stock_transactions

  validates :name, presence: true, uniqueness: true

  # Helper to get total units in this warehouse
  def total_stock_count
    stock_transactions.sum(:quantity)
  end
end