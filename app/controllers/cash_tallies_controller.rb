# app/controllers/cash_tallies_controller.rb
class CashTalliesController < ApplicationController
  before_action :set_cash_account, only: [:new, :create]

  def index
    @start_date = params[:start_date].presence || Date.today.beginning_of_month
    @end_date = params[:end_date].presence || Date.today
    
    @tallies = CashTally.where(created_at: @start_date.to_date.beginning_of_day..@end_date.to_date.end_of_day)
                        .order(created_at: :desc)
                        
    respond_to do |format|
      format.html
      format.csv { send_data generate_csv(@tallies), filename: "cash_tallies_#{@start_date}.csv" }
    end
  end

  def show
    @tally = CashTally.find(params[:id])
  end

  def new
    @cash_tally = CashTally.new(account: @cash_account)
  end

  def create
    @cash_tally = CashTally.new(tally_params)
    
    if @cash_tally.save
      redirect_to cash_tallies_path, notice: "Daily cash closing completed successfully."
    else
      # Re-finding the account is crucial here to prevent the 'nil' error on re-render
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_cash_account
    @cash_account = Account.find_by(name: "Cash in Hand")
    if @cash_account.nil?
      redirect_to accounts_path, alert: "System Error: 'Cash in Hand' account not found. Please create it first."
    end
  end

  def tally_params
    params.require(:cash_tally).permit(:account_id, :physical_amount, :note)
  end

  def generate_csv(tallies)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      # Define Column Headers
      csv << ["Date", "System Amount (PKR)", "Physical Amount (PKR)", "Difference (PKR)", "Notes"]

      tallies.each do |tally|
        csv << [
          tally.created_at.strftime("%Y-%m-%d %H:%M"),
          tally.system_amount,
          tally.physical_amount,
          tally.difference,
          tally.note
        ]
      end
    end
  end
end