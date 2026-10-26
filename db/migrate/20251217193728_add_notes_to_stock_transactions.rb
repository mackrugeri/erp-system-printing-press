class AddNotesToStockTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_transactions, :notes, :text
  end
end
