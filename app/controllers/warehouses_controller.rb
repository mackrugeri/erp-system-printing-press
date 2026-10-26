class WarehousesController < ApplicationController
  def index
    @warehouses = Warehouse.all
  end

  def show
    @warehouse = Warehouse.find(params[:id])
    # Logic to get current stock levels for items specifically in THIS warehouse
    @inventory = Item.joins(:stock_transactions)
                     .where(stock_transactions: { warehouse_id: @warehouse.id })
                     .group(:id)
                     .select("items.*, SUM(stock_transactions.quantity) as quantity_here")
  end

  def new
    @warehouse = Warehouse.new
  end

  def create
    @warehouse = Warehouse.new(warehouse_params)
    if @warehouse.save
      redirect_to warehouses_path, notice: "Warehouse created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @warehouse = Warehouse.find(params[:id])
    if @warehouse.update(warehouse_params)
      redirect_to warehouses_path, notice: "Warehouse updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
    @warehouse = Warehouse.find(params[:id])
  end

  def destroy
    @warehouse = Warehouse.find(params[:id])
    if @warehouse.stock_transactions.any?
      redirect_to warehouses_path, alert: "Cannot delete warehouse with stock history."
    else
      @warehouse.destroy
      redirect_to warehouses_path, notice: "Warehouse removed."
    end
  end

  private

  def warehouse_params
    params.require(:warehouse).permit(:name, :location)
  end
end