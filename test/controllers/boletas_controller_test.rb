require "test_helper"

class BoletasControllerTest < ActionDispatch::IntegrationTest
  test "sube una boleta y precarga los datos extraídos" do
    fake_service = Object.new
    def fake_service.extraer_datos_boleta
      {
      "comercio" => "Tienda",
      "rut_emisor" => "76.123.456-7",
      "monto_total" => 12_990,
      "moneda" => "CLP",
      "fecha" => "2026-09-13"
      }
    end
    original_new = GeminiService.method(:new)
    GeminiService.define_singleton_method(:new) { |*_args| fake_service }

    begin
      assert_difference("Boleta.count", 1) do
        post boletas_path, params: { boleta: { archivo: uploaded_file } }
      end
    ensure
      GeminiService.define_singleton_method(:new, original_new)
    end

    assert_response :success
    assert_select "input[name='boleta[comercio]'][value='Tienda']"
    assert_select "input[name='boleta[rut_emisor]'][value='76.123.456-7']"
    assert_select "select[name='boleta[moneda]'] option[selected][value='CLP']"
  end

  test "rechaza archivos con tipo no permitido" do
    assert_no_difference("Boleta.count") do
      post boletas_path, params: { boleta: { archivo: uploaded_file("text/plain", "boleta.txt") } }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /PDF, JPG o PNG/
  end

  test "confirma y consulta una boleta" do
    boleta = Boleta.create!(
      comercio: "Tienda",
      rut_emisor: "76.123.456-7",
      monto_total: 12_990,
      moneda: "CLP",
      fecha: Date.new(2026, 9, 13)
    )

    patch boleta_path(boleta), params: {
      boleta: { comercio: "Tienda corregida", rut_emisor: boleta.rut_emisor, monto_total: 13_000, moneda: "CLP", fecha: boleta.fecha }
    }

    assert_redirected_to boletas_path
    follow_redirect!
    assert_select "body", /Tienda corregida/
    assert_equal 13_000, boleta.reload.monto_total.to_i
  end

  test "elimina una boleta individual" do
    boleta = Boleta.create!(
      comercio: "Tienda",
      rut_emisor: "76.123.456-7",
      monto_total: 12_990,
      moneda: "CLP",
      fecha: Date.new(2026, 9, 13)
    )

    assert_difference("Boleta.count", -1) do
      delete boleta_path(boleta)
    end

    assert_redirected_to boletas_path
  end

  test "limpia solo boletas incompletas" do
    incompleta = Boleta.new
    incompleta.save!(validate: false)
    valida = Boleta.create!(
      comercio: "Tienda",
      rut_emisor: "76.123.456-7",
      monto_total: 12_990,
      moneda: "CLP",
      fecha: Date.new(2026, 9, 13)
    )

    assert_difference("Boleta.count", -1) do
      delete limpiar_incompletas_boletas_path
    end

    assert_not Boleta.exists?(incompleta.id)
    assert Boleta.exists?(valida.id)
    assert_redirected_to boletas_path
  end

  private

  def uploaded_file(content_type = "image/png", filename = "boleta.png")
    Rack::Test::UploadedFile.new(StringIO.new("contenido de prueba"), content_type, original_filename: filename)
  end
end
