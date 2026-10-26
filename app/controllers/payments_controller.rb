# app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  def index
    @payments = Payment.includes(:contact, :account).order(payment_date: :desc)
  end

  def new
    # If we come from a contact page, pre-fill the contact
    @payment = Payment.new(
      contact_id: params[:contact_id], 
      amount: params[:suggested_amount],
      payment_date: Date.today
    )
    set_form_data
  end

  def create
    @payment = Payment.new(payment_params)
    if @payment.save
      redirect_to contact_path(@payment.contact), notice: "Payment of #{helpers.number_to_currency(@payment.amount)} recorded successfully."
    else
      set_form_data
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_form_data
    # Only allow payments to/from accounts that represent actual money
    @cash_accounts = Account.where("name ILIKE ? OR name ILIKE ?", "%Cash%", "%Bank%")
    @contacts = Contact.all.order(:name)
  end

  def payment_params
    params.require(:payment).permit(:contact_id, :account_id, :amount, :payment_date, :payment_method, :note)
  end
end