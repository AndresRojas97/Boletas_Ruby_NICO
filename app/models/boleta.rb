class Boleta < ApplicationRecord
  has_one_attached :archivo

  validates :comercio, :rut_emisor, :monto_total, :fecha, presence: true
  validates :monto_total, numericality: { greater_than_or_equal_to: 0 }
  validates :moneda, inclusion: { in: %w[CLP USD EUR] }
end
