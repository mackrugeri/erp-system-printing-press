class StockTransactionsController < ApplicationController
  before_action :set_stock_transaction, only: [:edit, :update]

  def new
    @stock_transaction = StockTransaction.new
    @items = Item.all
    @warehouses = Warehouse.all
  end

  def create
    @stock_transaction = StockTransaction.new(stock_params)
    
    if @stock_transaction.save
      # Redirect to the warehouse or item to see the result
      redirect_to warehouse_path(@stock_transaction.warehouse_id), notice: "Stock updated."
    else
      @items = Item.all
      @warehouses = Warehouse.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @items = Item.all
    @warehouses = Warehouse.all
  end

  def update
    if @stock_transaction.update(stock_params)
      # Redirect back to the item to see the updated balance
      redirect_to item_path(@stock_transaction.item_id), notice: "Stock movement updated successfully."
    else
      @items = Item.all
      @warehouses = Warehouse.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @stock_transaction = StockTransaction.find(params[:id])
    @item = @stock_transaction.item # Save reference to redirect back to the correct item

    if @stock_transaction.destroy
      redirect_to item_path(@item), notice: "Stock movement was successfully reversed/deleted."
    else
      redirect_to item_path(@item), alert: "Failed to delete the transaction."
    end
  end

  private

  def set_stock_transaction
    @stock_transaction = StockTransaction.find(params[:id])
  end

  def stock_params
    params.require(:stock_transaction).permit(:item_id, :warehouse_id, :quantity, :transaction_type, :notes)
  end
end