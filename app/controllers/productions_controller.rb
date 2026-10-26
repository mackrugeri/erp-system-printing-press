# app/controllers/productions_controller.rb
class ProductionsController < ApplicationController
  def index
    @productions = StockTransaction.where(transaction_type: 'production_output')
                                   .includes(:item, :warehouse)
                                   .order(created_at: :desc)
  end

  def show
    @output_transaction = StockTransaction.find(params[:id])
    @journal = @output_transaction.journal_entry
    
    # Accurate audit trail: Find all transactions linked to the same Journal Entry
    if @journal
      @consumptions = @journal.stock_transactions.where(transaction_type: 'production_consumption')
    else
      @consumptions = []
    end
  end

  def new
    @items = Item.all
    @warehouses = Warehouse.all
  end

  def create
    @item = Item.find(params[:item_id])
    @warehouse = Warehouse.find(params[:warehouse_id])
    @quantity = params[:quantity].to_f

    begin
      ManufacturingService.produce(@item, @quantity, @warehouse)
      redirect_to productions_path, notice: "Production run successfully posted to stock and ledger."
    rescue => e
      flash.now[:alert] = e.message
      @items = Item.joins(:bom_items).distinct
      @warehouses = Warehouse.all
      render :new, status: :unprocessable_entity
    end
  end
end