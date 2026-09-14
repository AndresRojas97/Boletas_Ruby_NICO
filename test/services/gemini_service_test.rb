require "test_helper"

class GeminiServiceTest < ActiveSupport::TestCase
  setup do
    @previous_api_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = "test-key"
  end

  teardown do
    ENV["GEMINI_API_KEY"] = @previous_api_key
  end

  test "devuelve los datos estructurados de Gemini" do
    response = {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              { "text" => "```json\n{\"comercio\":\"Tienda\",\"rut_emisor\":\"76.123.456-7\",\"monto_total\":12990,\"moneda\":\"CLP\",\"fecha\":\"2026-09-13\"}\n```" }
            ]
          }
        }
      ]
    }
    service = GeminiService.new(tempfile_path, "image/png", requester: ->(_uri, _payload) { [ 200, response.to_json ] })

    assert_equal "Tienda", service.extraer_datos_boleta["comercio"]
  end

  test "rechaza respuestas incompletas" do
    response = { "candidates" => [ { "content" => { "parts" => [ { "text" => '{"comercio":"Tienda"}' } ] } } ] }
    service = GeminiService.new(tempfile_path, "image/png", requester: ->(_uri, _payload) { [ 200, response.to_json ] })

    assert_raises(GeminiService::Error) { service.extraer_datos_boleta }
  end

  test "expone errores HTTP de Gemini" do
    service = GeminiService.new(tempfile_path, "image/png", requester: ->(_uri, _payload) { [ 400, '{"error":"bad request"}' ] })

    error = assert_raises(GeminiService::Error) { service.extraer_datos_boleta }
    assert_includes error.message, "HTTP 400"
  end

  private

  def tempfile_path
    file = Tempfile.new([ "boleta", ".png" ])
    file.write("image")
    file.close
    file.path
  end
end
