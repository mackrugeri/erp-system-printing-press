class AddWarehouseToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_reference :invoices, :warehouse, null: true, foreign_key: true
  end
end
