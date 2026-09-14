class CreateBoleta < ActiveRecord::Migration[8.1]
  def change
    create_table :boleta do |t|
      t.string :comercio
      t.string :rut_emisor
      t.decimal :monto_total
      t.date :fecha

      t.timestamps
    end
  end
end
