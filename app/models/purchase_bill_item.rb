class PurchaseBillItem < ApplicationRecord
  belongs_to :purchase_bill
  belongs_to :item
end