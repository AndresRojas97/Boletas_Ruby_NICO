require "net/http"
require "uri"
require "json"
require "base64"

class GeminiService
  GEMINI_MODEL = ENV.fetch("GEMINI_MODEL", "gemini-3.6-flash")
  PROMPT = "Extrae de esta boleta electrónica los siguientes datos en formato JSON estricto con estas llaves exactas: comercio, rut_emisor, monto_total (número sin separadores), moneda (código ISO 4217 CLP, USD o EUR según el símbolo y contexto del documento), fecha (formato AAAA-MM-DD). Para boletas chilenas con símbolo $, RUT o formato local, usa CLP. No incluyas texto fuera del JSON."

  class Error < StandardError; end

  def initialize(file_path, mime_type, requester: nil)
    @file_path = file_path
    @mime_type = mime_type
    @requester = requester
  end

  def extraer_datos_boleta
    api_key = ENV["GEMINI_API_KEY"]
    raise Error, "Falta configurar la variable de entorno GEMINI_API_KEY" unless api_key.present?

    uri = URI.parse("https://generativelanguage.googleapis.com/v1beta/models/#{GEMINI_MODEL}:generateContent?key=#{api_key}")

    file_bytes = File.read(@file_path, mode: "rb")
    file_base64 = Base64.strict_encode64(file_bytes)

    payload = {
      contents: [
        {
          parts: [
            {
              text: PROMPT
            },
            {
              inline_data: {
                mime_type: @mime_type,
                data: file_base64
              }
            }
          ]
        }
      ]
    }

    status, body = perform_request(uri, payload)
    raise Error, "Gemini respondió con HTTP #{status}: #{body}" unless status.between?(200, 299)

    parsed_response = JSON.parse(body)
    texto_respuesta = parsed_response.dig("candidates", 0, "content", "parts", 0, "text")
    raise Error, "Gemini no devolvió datos extraíbles" if texto_respuesta.blank?

    datos = JSON.parse(texto_respuesta.gsub(/```json|```/, "").strip)
    required_keys = %w[comercio rut_emisor monto_total moneda fecha]
    raise Error, "Gemini no devolvió todas las llaves requeridas" unless datos.is_a?(Hash) && required_keys.all? { |key| datos.key?(key) }
    datos["moneda"] = datos["moneda"].to_s.upcase
    raise Error, "Gemini devolvió una moneda no soportada" unless %w[CLP USD EUR].include?(datos["moneda"])

    datos
  rescue JSON::ParserError => e
    raise Error, "La respuesta de Gemini no contiene JSON válido: #{e.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error => e
    raise Error, "No fue posible comunicarse con Gemini: #{e.message}"
  end

  private

  def perform_request(uri, payload)
    return @requester.call(uri, payload) if @requester

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
    request.body = payload.to_json
    response = http.request(request)
    [ response.code.to_i, response.body ]
  end
end
