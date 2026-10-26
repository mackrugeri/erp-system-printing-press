class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :code # e.g., "1001"
      t.string :account_type, null: false # Asset, Liability, Income, Expense, Equity
      t.string :nature # Debit or Credit
      t.decimal :opening_balance, precision: 15, scale: 2, default: 0
      t.references :parent, foreign_key: { to_table: :accounts } # For hierarchy
      t.boolean :system_account, default: false # Prevent deletion of Cash/Bank

      t.timestamps
    end
  end
end
