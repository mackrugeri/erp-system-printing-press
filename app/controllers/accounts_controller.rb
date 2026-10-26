# app/controllers/accounts_controller.rb
class AccountsController < ApplicationController
  before_action :set_account, only: [:show, :edit, :update]

  def index
    @accounts = Account.order(created_at: :desc)
  end

  def show
    # Fetch all ledger entries for this specific account to show its "Ledger"
    @ledger_entries = @account.ledger_entries.joins(:journal_entry).order('journal_entries.date DESC')
  end

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      redirect_to accounts_path, notice: "Account created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to accounts_path, notice: "Account updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:name, :code, :account_type, :parent_id, :opening_balance)
  end
end