class JournalEntriesController < ApplicationController
  def index
    @journal_entries = JournalEntry.order(created_at: :desc).includes(ledger_entries: :account)
  end

  def new
    @journal_entry = JournalEntry.new
    @journal_entry.date = Date.today
    1.times { @journal_entry.ledger_entries.build }
  end

  # NEW ACTION: This responds to the "Add More" button
  def add_row
    @journal_entry = JournalEntry.new
    @new_line = @journal_entry.ledger_entries.build
    
    respond_to do |format|
      format.turbo_stream
    end
  end

  def create
    # 1. Initialize the header
    @journal_entry = JournalEntry.new(journal_params.except(:ledger_entries_attributes))

    # 2. Get the attributes safely
    ledger_attrs = params.dig(:journal_entry, :ledger_entries_attributes)

    if ledger_attrs.present?
      # Convert to a hash and loop through the values
      # This fixes the "Symbol into Integer" error by ensuring we only iterate over the data maps
      ledger_attrs.to_unsafe_h.each do |_index, entry_params|
        # Use string keys if symbol keys fail, or just use .with_indifferent_access
        p = entry_params.with_indifferent_access
        
        amount = p[:amount].to_f
        next if amount <= 0 || p[:debit_account_id].blank? || p[:credit_account_id].blank?

        # Create Debit Record
        @journal_entry.ledger_entries.build(
          account_id: p[:debit_account_id],
          debit: amount,
          credit: 0
        )

        # Create Credit Record
        @journal_entry.ledger_entries.build(
          account_id: p[:credit_account_id],
          debit: 0,
          credit: amount
        )
      end
    end

    if @journal_entry.save
      redirect_to journal_entries_path, notice: "Voucher #{@journal_entry.reference} posted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @journal_entry = JournalEntry.find(params[:id])
    @journal_entry.destroy
    redirect_to journal_entries_path, notice: "Journal entry deleted."
  end

  private

  def journal_params
    params.require(:journal_entry).permit(
      :date, :reference, :description,
      ledger_entries_attributes: [:id, :account_id, :debit, :credit, :_destroy]
    )
  end
end