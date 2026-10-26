# app/controllers/fiscal_closings_controller.rb
class FiscalClosingsController < ApplicationController
  def new
    @closing_date = Date.today.end_of_year
  end

  def create
    begin
      @journal = YearEndClosingService.close_fiscal_year!(
        Date.parse(params[:closing_date]), 
        params[:reference]
      )
      redirect_to journal_entry_path(@journal), notice: "Fiscal year closed successfully. Balances reset for the new year."
    rescue => e
      flash[:alert] = "Closing failed: #{e.message}"
      render :new
    end
  end
end