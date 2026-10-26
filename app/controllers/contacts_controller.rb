class ContactsController < ApplicationController
  before_action :set_contact, only: [:show, :edit, :update]

  # GET /contacts
  def index
    @customers = Contact.where(contact_type: 'Customer').order(:name)
    @vendors = Contact.where(contact_type: 'Vendor').order(:name)
  end

  # GET /contacts/1
  def show
    @contact = Contact.find(params[:id])
    
    # Requirement 6: Vendor/Customer Ledger Report with Date Filtering
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today.beginning_of_year
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today
    
    # Fetch ledger entries specifically for this contact's account
    @ledger_entries = LedgerEntry.where(account_id: @contact.account_id)
                                .joins(:journal_entry)
                                .where(journal_entries: { date: @start_date..@end_date })
                                .order('journal_entries.date DESC')
  end

  # GET /contacts/new
  def new
    @contact = Contact.new(contact_type: params[:type] || 'Customer')
  end

  # GET /contacts/1/edit
  def edit
  end

  # POST /contacts
  def create
    @contact = Contact.new(contact_params)
    
    Contact.transaction do
      # Requirement 2.4: Auto-create COA Account
      parent_name = @contact.contact_type == 'Vendor' ? 'Accounts Payable' : 'Accounts Receivable'
      parent_acc = Account.find_by(name: parent_name)
      
      # Create the associated accounting ledger
      new_account = Account.create!(
        name: @contact.name,
        account_type: @contact.contact_type == 'Vendor' ? 'Liability' : 'Asset',
        parent: parent_acc,
        code: "CON-#{SecureRandom.hex(3).upcase}",
        opening_balance: 0
      )
      
      @contact.account = new_account
      
      if @contact.save
        redirect_to contacts_path, notice: "#{@contact.contact_type} created successfully."
      else
        raise ActiveRecord::Rollback
        render :new, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /contacts/1
  def update
    Contact.transaction do
      if @contact.update(contact_params)
        # Requirement: Sync name change with the Chart of Accounts
        @contact.account.update!(name: @contact.name) if @contact.account
        redirect_to contacts_path, notice: "Contact details updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:name, :contact_type, :email, :phone, :address, :tax_id)
  end
end