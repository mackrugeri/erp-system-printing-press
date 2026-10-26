# app/controllers/item_categories_controller.rb
class ItemCategoriesController < ApplicationController
  def index
    @categories = ItemCategory.all
  end

  def create
    @category = ItemCategory.new(category_params)
    if @category.save
      redirect_to item_categories_path, notice: "Category created."
    else
      @categories = ItemCategory.all
      render :index, status: :unprocessable_entity
    end
  end

  private

  def category_params
    params.require(:item_category).permit(:name, :description)
  end
end