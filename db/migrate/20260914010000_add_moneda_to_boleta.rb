class AddMonedaToBoleta < ActiveRecord::Migration[8.1]
  def change
    add_column :boleta, :moneda, :string, null: false, default: "CLP"
  end
end
