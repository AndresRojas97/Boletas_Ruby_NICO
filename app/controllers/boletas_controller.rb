class BoletasController < ApplicationController
  def index
    @boletas = Boleta.all
  end

  def new
    @boleta = Boleta.new
  end

  def create
    archivo_subido = params.dig(:boleta, :archivo)
    @boleta = Boleta.new

    unless archivo_valido?(archivo_subido)
      @boleta.errors.add(:archivo, "debe ser un PDF, JPG o PNG de hasta 10 MB")
      return render :new, status: :unprocessable_entity
    end

    @boleta.archivo.attach(archivo_subido)

    begin
      datos_extraidos = GeminiService.new(archivo_subido.tempfile.path, archivo_subido.content_type).extraer_datos_boleta
      @boleta.assign_attributes(datos_extraidos.slice("comercio", "rut_emisor", "monto_total", "moneda", "fecha"))
    rescue GeminiService::Error => e
      Rails.logger.error("Error procesando con Gemini: #{e.message}")
      @boleta.errors.add(:base, "No se pudo procesar la boleta con IA: #{e.message}")
      return render :new, status: :unprocessable_entity
    end

    if @boleta.save
      render :new
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @boleta = Boleta.find(params[:id])
    if @boleta.update(params.require(:boleta).permit(:comercio, :rut_emisor, :monto_total, :moneda, :fecha))
      redirect_to boletas_path, notice: "Boleta confirmada y guardada con éxito."
    else
      render :new
    end
  end

  def destroy
    boleta = Boleta.find(params[:id])
    boleta.destroy!
    redirect_to boletas_path, notice: "Boleta eliminada correctamente."
  end

  def limpiar_incompletas
    cantidad = boletas_incompletas.delete_all
    redirect_to boletas_path, notice: "#{cantidad} boleta(s) incompleta(s) eliminada(s)."
  end

  private

  def boletas_incompletas
    Boleta.where(
      "comercio IS NULL OR comercio = '' OR rut_emisor IS NULL OR rut_emisor = '' OR monto_total IS NULL OR fecha IS NULL"
    )
  end

  def archivo_valido?(archivo)
    archivo.present? &&
      archivo.respond_to?(:content_type) &&
      archivo.respond_to?(:tempfile) &&
      archivo.tempfile.size <= 10.megabytes &&
      %w[application/pdf image/jpeg image/png].include?(archivo.content_type)
  end
end
