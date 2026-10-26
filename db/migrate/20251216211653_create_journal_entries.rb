class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries do |t|
      t.date :date, null: false
      t.string :reference # Invoice # or Receipt #
      t.text :description
      t.string :entry_type # Sale, Purchase, Payment, Journal

      t.timestamps
    end
  end
end
