# app/models/stock_transaction.rb
class StockTransaction < ApplicationRecord
  belongs_to :item
  belongs_to :warehouse
  
  validates :quantity, presence: true, numericality: { other_than: 0 }
  validates :transaction_type, presence: true

  # BUG FIX: Validation to prevent negative stock
  validate :ensure_available_stock, on: :create
  
  before_save :adjust_quantity_sign

  private

  def adjust_quantity_sign
    # Added 'production_consumption' to the list of negative movements
    negative_types = ['sale', 'waste', 'return_to_vendor', 'production_consumption']
    
    if negative_types.include?(transaction_type.downcase)
      self.quantity = -quantity.abs
    else
      self.quantity = quantity.abs
    end
  end

  def ensure_available_stock
    # Only check if the transaction is reducing stock
    # Note: We use the logic from adjust_quantity_sign to determine if it's a reduction
    negative_types = ['sale', 'waste', 'return_to_vendor', 'production_consumption']
    return unless negative_types.include?(transaction_type.downcase)

    # Calculate current stock in the specific warehouse for this item
    current_balance = item.stock_transactions.where(warehouse: warehouse).sum(:quantity)
    
    # If the current balance plus the proposed reduction is less than zero, block it
    if (current_balance - quantity.abs) < 0
      errors.add(:quantity, "would result in negative stock in #{warehouse.name}. Available: #{current_balance}")
    end
  end
end