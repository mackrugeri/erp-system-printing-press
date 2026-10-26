# app/controllers/reports_controller.rb
require 'csv'
class ReportsController < ApplicationController
  def trial_balance
    @date = params[:date].present? ? params[:date].to_date : Date.today
    @accounts = Account.all.includes(:ledger_entries)

    # Logic: Sum debits and credits up to the selected date
    @total_debits = LedgerEntry.joins(:journal_entry)
                              .where(journal_entries: { date: ..@date })
                              .sum(:debit)
    @total_credits = LedgerEntry.joins(:journal_entry)
                                .where(journal_entries: { date: ..@date })
                                .sum(:credit)

    respond_to do |format|
      format.html
      format.csv { send_data generate_trial_balance_csv, filename: "trial_balance_#{@date}.csv" }
    end
  end

  def profit_and_loss
  # 1. Handle Date Range (Defaults provided if params are blank)
  @start_date = params[:start_date].present? ? params[:start_date].to_date : Date.today.beginning_of_month
  @end_date = params[:end_date].present? ? params[:end_date].to_date : Date.today
  
  @income_accounts = Account.where(account_type: 'Income')
  @expense_accounts = Account.where(account_type: 'Expense')
  
  # 2. Calculate Totals for the specific period
  @total_income = @income_accounts.sum { |a| a.balance_for_range(@start_date, @end_date) }
  @total_expenses = @expense_accounts.sum { |a| a.balance_for_range(@start_date, @end_date) }
  @net_profit = @total_income - @total_expenses

  respond_to do |format|
    format.html
    format.csv { send_data generate_p_and_l_csv, filename: "profit_and_loss_#{@start_date}_to_#{@end_date}.csv" }
    end
  end

  def balance_sheet
    @start_date = params[:start_date].present? ? params[:start_date].to_date : Date.today
    @end_date = params[:end_date].present? ? params[:end_date].to_date : Date.today

    # 1. Fetch the accounts
    @assets = Account.where(account_type: 'Asset')
    @liabilities = Account.where(account_type: 'Liability')
    @equity = Account.where(account_type: 'Equity')

    # 2. Calculate Balances up to the specific date
    # We use the same 'balance_for_range' logic for everything to stay consistent
    @total_assets = @assets.sum { |a| a.balance_for_range(@start_date, @end_date) }
    
    total_liabilities = @liabilities.sum { |a| a.balance_for_range(@start_date, @end_date) }
    total_equity_base = @equity.sum { |a| a.balance_for_range(@start_date, @end_date) }

    # 3. Calculate Retained Earnings (Profit/Loss up to this date)
    total_income = Account.where(account_type: 'Income').sum { |a| a.balance_for_range(@start_date, @end_date) }
    total_expense = Account.where(account_type: 'Expense').sum { |a| a.balance_for_range(@start_date, @end_date) }
    @retained_earnings = total_income - total_expense

    # 4. Final Equation: Assets = Liabilities + Equity + Retained Earnings
    @total_liabilities_equity = total_liabilities + total_equity_base + @retained_earnings

    respond_to do |format|
      format.html
      format.csv { send_data generate_balance_sheet_csv, filename: "balance_sheet_#{@start_date}_#{@end_date}.csv" }
    end
  end


  private

  def generate_balance_sheet_csv
    CSV.generate(headers: true) do |csv|
      csv << ["Balance Sheet as of #{@date}"]
      csv << []
      csv << ["ASSETS"]
      @assets.each { |a| csv << [a.name, a.balance] }
      csv << ["Total Assets", @total_assets]
      csv << []
      csv << ["LIABILITIES"]
      @liabilities.each { |a| csv << [a.name, a.balance] }
      csv << []
      csv << ["EQUITY"]
      @equity.each { |a| csv << [a.name, a.balance] }
      csv << ["Retained Earnings (Net Profit)", @retained_earnings]
      csv << ["Total Liabilities & Equity", @total_liabilities_equity]
    end
  end

  def generate_trial_balance_csv
    CSV.generate(headers: true) do |csv|
      csv << ["TRIAL BALANCE"]
      csv << ["As of Date:", @date]
      csv << []
      csv << ["Account Name", "Type", "Debit", "Credit"]
      
      @accounts.each do |account|
        balance = account.balance_for_range(Date.new(1900), @date)
        next if balance == 0
        
        row = [account.name, account.account_type]
        if account.debit_normal?
          row << balance << ""
        else
          row << "" << balance
        end
        csv << row
      end
      
      csv << []
      csv << ["TOTAL", "", @total_debits, @total_credits]
    end
  end

  def generate_p_and_l_csv
    CSV.generate(headers: true) do |csv|
      csv << ["PROFIT & LOSS STATEMENT"]
      csv << ["Period:", "#{@start_date} to #{@end_date}"]
      csv << []
      csv << ["Account Name", "Type", "Balance"]
      csv << ["INCOME"]
      @income_accounts.each { |a| csv << [a.name, a.account_type, a.balance_for_range(@start_date, @end_date)] }
      csv << ["Total Income", "", @total_income]
      csv << []
      csv << ["EXPENSES"]
      @expense_accounts.each { |a| csv << [a.name, a.account_type, a.balance_for_range(@start_date, @end_date)] }
      csv << ["Total Expenses", "", @total_expenses]
      csv << []
      csv << ["NET PROFIT", "", @net_profit]
    end
  end
end