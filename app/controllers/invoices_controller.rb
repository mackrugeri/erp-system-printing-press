class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update]
  before_action :ensure_draft, only: [:edit, :update]

  def index
    @start_date = params[:start_date].presence || Date.today.beginning_of_month
    @end_date = params[:end_date].presence || Date.today
    @invoices = Invoice.includes(:contact).where(date: @start_date..@end_date).order(date: :desc)
    @total_invoiced = @invoices.sum(&:total_amount)
    respond_to do |format|
      format.html
      format.csv { send_data generate_csv(@invoices), filename: "invoices_#{@start_date}.csv" }
    end
  end

  def new
    @invoice = Invoice.new
    # Build 3 empty rows by default so the user has space to type
    1.times { @invoice.invoice_items.build }
  end

  def edit
    # @invoice is set by before_action
    @invoice.invoice_items.build if @invoice.invoice_items.empty?
  end


  def create
    @invoice = Invoice.new(invoice_params)
    process_invoice_posting(:new)
  end

  def update
    @invoice.assign_attributes(invoice_params)
    process_invoice_posting(:edit)
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def ensure_draft
    redirect_to @invoice, alert: "Posted records cannot be modified." if @invoice.status == 'Posted'
  end

  def invoice_params
    params.require(:invoice).permit(
      :contact_id, :warehouse_id, :date, :total_amount,
      invoice_items_attributes: [:id, :item_id, :quantity, :unit_price, :_destroy] # Must include :quantity and :unit_price
    )
  end

  def generate_csv(invoices)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      # Define your CSV Headers
      csv << ["Date", "Invoice #", "Customer", "Status", "Amount"]

      invoices.each do |invoice|
        csv << [
          invoice.date,
          invoice.invoice_number,
          invoice.contact&.name,
          invoice.status,
          invoice.total_amount
        ]
      end
    end
  end

  def process_invoice_posting(render_view)
    is_posting = params[:commit].to_s.downcase.include?("post")
    @invoice.status = is_posting ? "Posted" : "Draft"
    
    # Variable to capture error message so it survives the Rollback
    posting_error = nil

    ActiveRecord::Base.transaction do
      if @invoice.save
        if is_posting
          begin
            # Fetch the Sales Income account
            sales_acc = Account.find_by!(name: "Sales Income")
            
            # Trigger the logic in the model
            @invoice.post_to_ledger_and_stock!(sales_acc.id)
            
            # Success: Return and redirect immediately
            return redirect_to @invoice, notice: "Invoice successfully posted to ledger."
          rescue StandardError => e
            # Capture the specific error (e.g., "Insufficient Stock")
            posting_error = e.message
            raise ActiveRecord::Rollback
          end
        else
          # Draft saved successfully
          return redirect_to @invoice, notice: "Invoice saved as Draft."
        end
      else
        # Standard validation failed
        raise ActiveRecord::Rollback
      end
    end

    # --- If we reach here, something failed (Rollback or Validation) ---
    
    # 1. Manually add the captured error to the errors collection
    if posting_error.present?
      @invoice.errors.add(:base, "Ledger Error: #{posting_error}")
    end

    # 2. Revert status for UI consistency
    @invoice.status = "Draft"

    # 3. Re-build items if empty for the form fields
    @invoice.invoice_items.build if @invoice.invoice_items.empty?

    render render_view, status: :unprocessable_entity
  end
end