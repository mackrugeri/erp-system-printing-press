# app/services/year_end_closing_service.rb
class YearEndClosingService
  def self.close_fiscal_year!(closing_date, user_reference)
    ActiveRecord::Base.transaction do
      # 1. Calculate Net Profit (Income - Expenses)
      revenue = Account.where(account_type: 'Revenue').sum(&:balance)
      expenses = Account.where(account_type: 'Expense').sum(&:balance)
      net_profit = revenue - expenses

      # 2. Create the Closing Journal Entry
      journal = JournalEntry.create!(
        date: closing_date,
        description: "Fiscal Year Closing - #{closing_date.year}",
        reference: user_reference
      )

      # 3. Zero out Revenue Accounts (Debit Revenue to decrease to 0)
      Account.where(account_type: 'Revenue').each do |acc|
        if acc.balance != 0
          journal.ledger_entries.create!(account: acc, debit: acc.balance, credit: 0)
        end
      end

      # 4. Zero out Expense Accounts (Credit Expense to decrease to 0)
      Account.where(account_type: 'Expense').each do |acc|
        if acc.balance != 0
          journal.ledger_entries.create!(account: acc, debit: 0, credit: acc.balance)
        end
      end

      # 5. Move the Net Profit to Retained Earnings (Equity)
      retained_earnings = Account.find_or_create_by!(name: "Retained Earnings", account_type: "Equity")
      
      if net_profit > 0
        # Profit: Credit Equity
        journal.ledger_entries.create!(account: retained_earnings, debit: 0, credit: net_profit)
      elsif net_profit < 0
        # Loss: Debit Equity
        journal.ledger_entries.create!(account: retained_earnings, debit: net_profit.abs, credit: 0)
      end

      return journal
    end
  end
end