require "test_helper"

class BoletumTest < ActiveSupport::TestCase
  test "requiere los datos de la boleta" do
    boleta = Boleta.new

    assert_not boleta.valid?
    assert_includes boleta.errors[:comercio], "can't be blank"
    assert_includes boleta.errors[:fecha], "can't be blank"
  end

  test "acepta solo monedas soportadas" do
    boleta = Boleta.new(moneda: "GBP")

    assert_not boleta.valid?
    assert_includes boleta.errors[:moneda], "is not included in the list"
  end

  test "requiere un monto no negativo" do
    boleta = Boleta.new(monto_total: -1)

    assert_not boleta.valid?
    assert_includes boleta.errors[:monto_total], "must be greater than or equal to 0"
  end
end
