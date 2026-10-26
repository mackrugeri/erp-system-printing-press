# Clear existing data to avoid duplicates
puts "Cleaning database..."
[LedgerEntry, JournalEntry, Invoice, PurchaseBill, Item, Contact, Account, ItemCategory, Warehouse].each(&:delete_all)

puts "Creating Chart of Accounts..."

# --- 1. Assets ---
Account.create!(name: "Cash in Hand", account_type: "Asset", code: "1001")

accounts_to_create = [
  { name: "Sales Income", type: "Income",code: "5000" },
  { name: "Accounts Receivable", type: "Asset", code: "8000" }
  { name: "Accounts Payable", type: "Liability", code: "9000" }
  { name: "Inventory Asset", type: "Expense", code: "10000"}
]

accounts_to_create.each do |acc_data|
  # Use find_or_initialize_by to avoid duplicates
  acc = Account.find_or_initialize_by(name: acc_data[:name])
  acc.account_type = acc_data[:type]
  acc.code = acc_data[:code]
  
  if acc.save
    puts "Verified Account: #{acc.name}"
  else
    # This will tell you EXACTLY what the model is complaining about
    puts "Failed to create #{acc.name}: #{acc.errors.full_messages.join(', ')}"
  end
end

  assets = Account.create!(name: "Assets", account_type: "Asset", code: "1000")
  cash = Account.create!(name: "Cash in Hand", account_type: "Asset", code: "1100", parent: assets, system_account: true)
  bank = Account.create!(name: "Main Bank Account", account_type: "Asset", code: "1200", parent: assets)
  ar = Account.create!(name: "Accounts Receivable", account_type: "Asset", code: "1300", parent: assets, system_account: true)
  inventory = Account.create!(name: "Inventory Asset", account_type: "Asset", code: "1400", parent: assets, system_account: true)

# --- 2. Liabilities ---
  liabilities = Account.create!(name: "Liabilities", account_type: "Liability", code: "2000")
  ap = Account.create!(name: "Accounts Payable", account_type: "Liability", code: "2100", parent: liabilities, system_account: true)

# --- 3. Equity ---
  equity = Account.create!(name: "Equity", account_type: "Equity", code: "3000")
  capital = Account.create!(name: "Owner Capital", account_type: "Equity", code: "3100", parent: equity)

# --- 4. Income ---
  income = Account.create!(name: "Income", account_type: "Income", code: "4000")
  sales_revenue = Account.create!(name: "Sales Revenue", account_type: "Income", code: "4100", parent: income)

# --- 5. Expenses ---
  expenses = Account.create!(name: "Expenses", account_type: "Expense", code: "5000")
  cogs = Account.create!(name: "Cost of Goods Sold", account_type: "Expense", code: "5100", parent: expenses)
  rent = Account.create!(name: "Rent Expense", account_type: "Expense", code: "5200", parent: expenses)

puts "Creating Categories and Warehouses..."
raw_materials = ItemCategory.create!(name: "Raw Materials")
finished_goods = ItemCategory.create!(name: "Finished Goods")
main_wh = Warehouse.create!(name: "Main Warehouse", location: "Building A")

puts "Creating Sample Items..."
bolt = Item.create!(name: "Steel Bolt", sku: "BOLT-001", item_type: "Raw Material", item_category: raw_materials, cost_price: 0.50)
engine = Item.create!(name: "V8 Engine Block", sku: "ENG-V8", item_type: "Finished Good", item_category: finished_goods, unit_price: 5000.00)

puts "Creating Sample Contacts..."
Customer.create!(name: "Global Motors", contact_type: "Customer", account: ar)
Vendor.create!(name: "Steel Supplies Inc", contact_type: "Vendor", account: ap)

puts "Creating Fiscal Period..."
FiscalPeriod.create!(name: "FY 2025", start_date: "2025-01-01", end_date: "2025-12-31", closed: false)


# Run this in your terminal
ItemCategory.create!([
  { name: "Raw Materials" },
  { name: "Work in Process" },
  { name: "Finished Goods" },
  { name: "Consumables" }
])
puts "Database Seeded Successfully!"