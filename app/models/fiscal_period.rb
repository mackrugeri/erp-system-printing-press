class FiscalPeriod < ApplicationRecord
  validates :name, :start_date, :end_date, presence: true

  def self.is_open?(date)
    period = where("start_date <= ? AND end_date >= ?", date, date).first
    period && !period.closed?
  end
end