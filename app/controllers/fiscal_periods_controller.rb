# app/controllers/fiscal_periods_controller.rb
class FiscalPeriodsController < ApplicationController
  def index
    @fiscal_periods = FiscalPeriod.order(start_date: :desc)
  end

  def create
    @fiscal_period = FiscalPeriod.new(fiscal_params)
    if @fiscal_period.save
      redirect_to fiscal_periods_path, notice: "New fiscal period defined."
    else
      render :index, status: :unprocessable_entity
    end
  end

  # Special Action: Close the Period
  def close
    @fiscal_period = FiscalPeriod.find(params[:id])
    if @fiscal_period.update(closed: true)
      redirect_to fiscal_periods_path, notice: "Fiscal period has been locked."
    end
  end

  private

  def fiscal_params
    params.require(:fiscal_period).permit(:name, :start_date, :end_date)
  end
end