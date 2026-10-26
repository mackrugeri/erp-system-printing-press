class CreateFiscalPeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_periods do |t|
      t.string :name # e.g., "FY 2025"
      t.date :start_date
      t.date :end_date
      t.boolean :closed, default: false
      t.timestamps
    end
  end
end
