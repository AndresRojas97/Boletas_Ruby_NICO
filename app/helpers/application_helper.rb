module ApplicationHelper
  def formato_monto_boleta(boleta)
    case boleta.moneda
    when "CLP"
      number_to_currency(boleta.monto_total, unit: "$", precision: 0, delimiter: ".", separator: ",", format: "%u%n")
    when "USD"
      number_to_currency(boleta.monto_total, unit: "US$", precision: 2, delimiter: ",", separator: ".", format: "%u%n")
    when "EUR"
      number_to_currency(boleta.monto_total, unit: "€", precision: 2, delimiter: ".", separator: ",", format: "%n %u")
    end
  end
end
