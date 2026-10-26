class DashboardController < ApplicationController
  def index
    # 1. Financial Metrics (Current Balances)
    @cash_on_hand = Account.find_by(name: "Cash in Hand")&.balance || 0
    
    # Calculate Receivables and Payables dynamically from Accounts
    @total_asset_balance = Account.where(account_type: 'Asset')
                                .sum(&:balance)
                                
    @total_payables = Account.where(account_type: 'Liability')
                             .sum(&:balance)
                             
    @inventory_value = Account.find_by(name: "Finished Goods Inventory")&.balance || 0

    # 2. Profitability Metrics (Requirement 3.4)
    @revenue = Account.find_by(name: "Sales Income")&.balance || 0
    @purchase =  Account.find_by(name: "Inventory Asset")&.balance || 0
    # @cogs = Account.find_by(name: "Cost of Goods Sold")&.balance || 0
    @gross_profit = @revenue - @purchase
    
    # 3. Operations Data
    @recent_invoices = Invoice.includes(:contact).order(created_at: :desc).limit(5)
    
    # FIX: Calculate stock in memory to avoid PG::UndefinedColumn error
    # This assumes your Item model has a 'total_stock' method
    @low_stock_items = Item.all.select { |item| item.total_stock <= 10 }.first(5)
  end
end