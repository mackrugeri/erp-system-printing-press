class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :contact, null: false, foreign_key: true # The Customer
      t.string :invoice_number
      t.date :date
      t.decimal :total_amount, precision: 15, scale: 2
      t.string :status # Draft, Paid, Overdue
      t.references :journal_entry, foreign_key: true

      t.timestamps
    end
  end
end
