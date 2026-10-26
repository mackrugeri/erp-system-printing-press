# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_19_205718) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "account_type", null: false
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "nature"
    t.decimal "opening_balance", precision: 15, scale: 2, default: "0.0"
    t.bigint "parent_id"
    t.boolean "system_account", default: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_accounts_on_parent_id"
  end

  create_table "bom_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.integer "material_id", null: false
    t.decimal "quantity", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_bom_items_on_item_id"
    t.index ["material_id"], name: "index_bom_items_on_material_id"
  end

  create_table "cash_tallies", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.decimal "difference", precision: 15, scale: 2
    t.text "note"
    t.decimal "physical_amount", precision: 15, scale: 2
    t.decimal "system_amount", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_cash_tallies_on_account_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "account_id"
    t.text "address"
    t.string "contact_type"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_contacts_on_account_id"
  end

  create_table "fiscal_periods", force: :cascade do |t|
    t.boolean "closed", default: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "name"
    t.date "start_date"
    t.datetime "updated_at", null: false
  end

  create_table "invoice_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.bigint "item_id", null: false
    t.integer "quantity"
    t.decimal "subtotal", precision: 15, scale: 2
    t.decimal "unit_price", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["item_id"], name: "index_invoice_items_on_item_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.string "invoice_number"
    t.bigint "journal_entry_id"
    t.string "status"
    t.decimal "total_amount", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id"
    t.index ["contact_id"], name: "index_invoices_on_contact_id"
    t.index ["journal_entry_id"], name: "index_invoices_on_journal_entry_id"
    t.index ["warehouse_id"], name: "index_invoices_on_warehouse_id"
  end

  create_table "item_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "items", force: :cascade do |t|
    t.decimal "cost_price", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.bigint "item_category_id"
    t.string "item_type"
    t.string "name", null: false
    t.integer "reorder_level", default: 0
    t.string "sku"
    t.decimal "standard_cost"
    t.decimal "unit_price", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.index ["item_category_id"], name: "index_items_on_item_category_id"
    t.index ["sku"], name: "index_items_on_sku", unique: true
  end

  create_table "journal_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "description"
    t.string "entry_type"
    t.string "reference"
    t.datetime "updated_at", null: false
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.decimal "credit", precision: 15, scale: 2, default: "0.0"
    t.decimal "debit", precision: 15, scale: 2, default: "0.0"
    t.bigint "journal_entry_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["journal_entry_id"], name: "index_ledger_entries_on_journal_entry_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount"
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.bigint "journal_entry_id", null: false
    t.text "note"
    t.date "payment_date"
    t.string "payment_method"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_payments_on_account_id"
    t.index ["contact_id"], name: "index_payments_on_contact_id"
    t.index ["journal_entry_id"], name: "index_payments_on_journal_entry_id"
  end

  create_table "purchase_bill_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.bigint "purchase_bill_id", null: false
    t.decimal "quantity", precision: 10, scale: 2
    t.decimal "unit_price", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_purchase_bill_items_on_item_id"
    t.index ["purchase_bill_id"], name: "index_purchase_bill_items_on_purchase_bill_id"
  end

  create_table "purchase_bills", force: :cascade do |t|
    t.string "bill_number"
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.bigint "journal_entry_id"
    t.string "status"
    t.decimal "total_amount", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id"
    t.index ["contact_id"], name: "index_purchase_bills_on_contact_id"
    t.index ["journal_entry_id"], name: "index_purchase_bills_on_journal_entry_id"
    t.index ["warehouse_id"], name: "index_purchase_bills_on_warehouse_id"
  end

  create_table "stock_transactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.bigint "journal_entry_id"
    t.text "notes"
    t.decimal "quantity", precision: 10, scale: 2
    t.string "transaction_type"
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id"
    t.index ["item_id"], name: "index_stock_transactions_on_item_id"
    t.index ["journal_entry_id"], name: "index_stock_transactions_on_journal_entry_id"
    t.index ["warehouse_id"], name: "index_stock_transactions_on_warehouse_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "accounts", "accounts", column: "parent_id"
  add_foreign_key "bom_items", "items"
  add_foreign_key "cash_tallies", "accounts"
  add_foreign_key "contacts", "accounts"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "items"
  add_foreign_key "invoices", "contacts"
  add_foreign_key "invoices", "journal_entries"
  add_foreign_key "invoices", "warehouses"
  add_foreign_key "items", "item_categories"
  add_foreign_key "ledger_entries", "accounts"
  add_foreign_key "ledger_entries", "journal_entries"
  add_foreign_key "payments", "accounts"
  add_foreign_key "payments", "contacts"
  add_foreign_key "payments", "journal_entries"
  add_foreign_key "purchase_bill_items", "items"
  add_foreign_key "purchase_bill_items", "purchase_bills"
  add_foreign_key "purchase_bills", "contacts"
  add_foreign_key "purchase_bills", "journal_entries"
  add_foreign_key "purchase_bills", "warehouses"
  add_foreign_key "stock_transactions", "items"
  add_foreign_key "stock_transactions", "journal_entries"
  add_foreign_key "stock_transactions", "warehouses"
end
