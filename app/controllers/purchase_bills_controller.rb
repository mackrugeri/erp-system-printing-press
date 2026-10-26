class PurchaseBillsController < ApplicationController

  before_action :set_bill, only: [:show, :edit, :update]
  before_action :ensure_draft, only: [:edit, :update]


  def index
    @start_date = params[:start_date].presence || Date.today.beginning_of_month
    @end_date = params[:end_date].presence || Date.today
    
    @purchase_bills = PurchaseBill.includes(:contact)
                                  .where(date: @start_date..@end_date)
                                  .order(date: :desc)
                                  
    @total_billed = @purchase_bills.sum { |bill| bill.total_amount.to_f }

    respond_to do |format|
      format.html
      format.csv { send_data generate_csv(@purchase_bills), filename: "purchase_bills_#{@start_date}.csv" }
    end
  end

  def show
    @purchase_bill = PurchaseBill.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Bill_#{@purchase_bill.bill_number}",
              template: "purchase_bills/show",
              formats: [:html],
              layout: 'pdf',
              show_as_html: params[:debug].present?
      end
    end
  end

  def new
    @purchase_bill = PurchaseBill.new
    @purchase_bill.purchase_bill_items.build
  end

  def edit
    # @purchase_bill is set by before_action
    @purchase_bill.purchase_bill_items.build if @purchase_bill.purchase_bill_items.empty?
  end

  def create
    @purchase_bill = PurchaseBill.new(purchase_bill_params)
    process_purchase_save(:new)
  end

  def update
    @purchase_bill.assign_attributes(purchase_bill_params)
    process_purchase_save(:edit)
  end


  private

  def set_bill
    @purchase_bill = PurchaseBill.find(params[:id])
  end

  def ensure_draft
    redirect_to @purchase_bill, alert: "Posted records cannot be modified." if @purchase_bill.status == 'Posted'
  end

  def purchase_bill_params
    params.require(:purchase_bill).permit(
      :contact_id, :warehouse_id, :date, :bill_number, :total_amount, :status,
      purchase_bill_items_attributes: [:id, :item_id, :quantity, :unit_price, :_destroy]
    )
  end

  def generate_csv(purchase_bills)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      # Define your CSV Headers
      csv << ["Date", "Bill #", "Customer", "Status", "Amount"]

      purchase_bills.each do |purchase_bill|
        csv << [
          purchase_bill.date,
          purchase_bill.bill_number,
          purchase_bill.contact&.name,
          purchase_bill.status,
          purchase_bill.total_amount
        ]
      end
    end
  end

  def process_purchase_save(render_view)
    is_posting = params[:commit].to_s.downcase.include?("post")
    @purchase_bill.status = is_posting ? "Posted" : "Draft"
    
    # Capture error to survive the Rollback
    posting_error = nil

    ActiveRecord::Base.transaction do
      if @purchase_bill.save
        if is_posting
          begin
            inventory_acc = Account.find_by!(name: "Inventory Asset")
            
            # Ensure warehouse is present
            if @purchase_bill.warehouse_id.blank?
              raise "Please select a Warehouse to receive inventory."
            end

            # Model method to handle Ledger entries and Stock increase
            @purchase_bill.post_to_ledger_and_inventory!(inventory_acc.id)
            
            return redirect_to purchase_bills_path, notice: "Bill successfully posted and inventory updated."
          rescue StandardError => e
            posting_error = e.message
            raise ActiveRecord::Rollback
          end
        else
          return redirect_to purchase_bills_path, notice: "Bill saved as Draft."
        end
      else
        # Standard validation failed
        raise ActiveRecord::Rollback
      end
    end

    # --- Reached only if Rollback or Validation Failure occurs ---
    
    # Re-add the captured error so it shows in the red box on the UI
    @purchase_bill.errors.add(:base, "Ledger Error: #{posting_error}") if posting_error.present?
    
    # Revert status for UI consistency
    @purchase_bill.status = "Draft"
    
    # Build items for fields_for if they were lost
    @purchase_bill.purchase_bill_items.build if @purchase_bill.purchase_bill_items.empty?

    render render_view, status: :unprocessable_entity
  end
end