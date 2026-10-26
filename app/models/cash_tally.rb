# app/models/cash_tally.rb
class CashTally < ApplicationRecord
  belongs_to :account
  
  validates :physical_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  before_create :calculate_difference

  private

  def calculate_difference
    # We use &. to be extra safe against nil errors
    self.system_amount = account&.balance || 0
    self.difference = physical_amount - system_amount
  end
end