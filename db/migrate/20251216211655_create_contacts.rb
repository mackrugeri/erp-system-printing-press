class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :contact_type # Customer or Vendor
      t.string :email
      t.string :phone
      t.text :address
      t.references :account, foreign_key: true # Links to AR or AP in COA

      t.timestamps
    end
  end
end
