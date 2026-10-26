# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  def index
    @items = Item.includes(:item_category).all
  end

  def show
    @item = Item.find(params[:id])
    # Show the audit trail of how stock reached the current level
    @stock_history = @item.stock_transactions.order(created_at: :desc)
  end

  def new
    @item = Item.new
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to items_path, notice: "Item successfully added to catalog."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @item = Item.find(params[:id])
  end

  def update
    @item = Item.find(params[:id])
    if @item.update(item_params)
      redirect_to items_path, notice: "Item was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item = Item.find(params[:id])
    if @item.stock_transactions.any?
      redirect_to items_path, alert: "Cannot delete item with existing stock history. Archive it instead."
    else
      @item.destroy
      redirect_to items_path, notice: "Item removed from catalog."
    end
  end

  private

  def item_params
    params.require(:item).permit(:name, :sku, :item_type, :item_category_id, :unit_price, :cost_price, :reorder_level, :standard_cost)
  end
end