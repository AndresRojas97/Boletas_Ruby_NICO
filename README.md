# Entrevista Técnica: registro de boletas con IA

Aplicación Rails para subir una boleta chilena en PDF o imagen, extraer sus
datos con Gemini, revisar el resultado y guardarlo en PostgreSQL.

## Requisitos

- Ruby `4.0.0` (ver `.ruby-version`).
- Rails `8.1`.
- PostgreSQL 9.5 o superior.
- Una API key de Gemini con acceso a `gemini-3.6-flash`.

## Instalación y ejecución

1. Instala PostgreSQL y crea un usuario con permisos para crear bases de datos.
2. Instala las dependencias:

   ```bash
   bundle install
   ```

3. Configura las credenciales de PostgreSQL en `config/database.yml` o mediante
   las variables que use tu entorno. En desarrollo puedes definir
   `POSTGRES_PASSWORD`; en producción Rails utiliza `DATABASE_URL`.
4. Configura la API key de Gemini. En PowerShell:

   ```powershell
   $env:GEMINI_API_KEY = "tu_api_key"
   ```

   Opcionalmente puedes cambiar el modelo con `GEMINI_MODEL`; por defecto se usa
   `gemini-3.6-flash`.
5. Crea la base de datos y ejecuta las migraciones:

   ```bash
   bin/rails db:prepare
   ```

6. Inicia el servidor:

   ```bash
   bin/rails server
   ```

   Visita <http://localhost:3000>.

## Producción

La aplicación está desplegada en Render:

- Aplicación: <https://boletas-ruby-nico.onrender.com>
- Base de datos: PostgreSQL administrado por Render

Para configurar el servicio de producción se deben definir las siguientes
variables de entorno en Render:

- `DATABASE_URL`: Internal Database URL de la base PostgreSQL de Render.
- `RAILS_MASTER_KEY`: contenido de `config/master.key`.
- `GEMINI_API_KEY`: clave privada de la API de Gemini.
- `GEMINI_MODEL`: opcional; por defecto `gemini-3.6-flash`.
- `RAILS_ENV`: `production`.

El comando de construcción ejecuta las migraciones y la compilación de assets:

```bash
bundle install && bundle exec rails assets:precompile && bundle exec rails db:prepare
```

La aplicación se inicia con:

```bash
bundle exec puma -C config/puma.rb
```

No se deben subir al repositorio `config/master.key` ni claves de API.

## Flujo de uso

1. Selecciona una boleta en PDF, JPG o PNG de hasta 10 MB.
2. Presiona **Procesar con IA**.
3. Gemini interpreta el documento y devuelve `comercio`, `rut_emisor`,
   `monto_total`, `moneda` (`CLP`, `USD` o `EUR`) y `fecha` en JSON. Las boletas
   chilenas se identifican como CLP.
4. Revisa o corrige los datos precargados.
5. Presiona **Confirmar y Guardar** para persistirlos en PostgreSQL.
6. Consulta los registros desde **Ver todas las boletas**.
7. En el listado puedes eliminar una boleta individual o usar **Limpiar boletas incompletas**
   para eliminar registros antiguos que no tengan comercio, RUT, monto o fecha.

## IA y OCR

La aplicación envía el PDF o la imagen directamente a Gemini mediante
`inline_data`. Gemini es un modelo multimodal, por lo que realiza la lectura
visual del documento y la extracción de texto dentro del mismo paso; no se
requiere un OCR externo como Tesseract para este flujo. Si se incorporaran
documentos escaneados de peor calidad, se podría agregar una etapa OCR dedicada
antes de enviar el texto al modelo.

El prompt utilizado es:

> Extrae de esta boleta electrónica chilena los siguientes datos en formato JSON
> estricto con estas llaves exactas: comercio, rut_emisor, monto_total (número
> sin separadores), moneda (código ISO 4217 CLP, USD o EUR según el símbolo y
> contexto del documento), fecha (formato AAAA-MM-DD). Para boletas chilenas con
> símbolo $, RUT o formato local, usa CLP. No incluyas texto fuera del JSON.

La respuesta se valida antes de mostrarla y los errores de API se informan en el
formulario en lugar de guardar una boleta incompleta.

## Pruebas

Ejecuta:

```bash
bin/rails test
```

Las pruebas cubren validaciones del modelo, respuestas válidas y erróneas de
Gemini, subida de archivos, precarga de datos, confirmación y consulta.

## Mejoras futuras

- Procesar archivos en segundo plano para no mantener abierta la petición web.
- Incorporar OCR dedicado para PDFs escaneados y una validación más avanzada del
  RUT chileno.
- Agregar autenticación, paginación y filtros al listado.
- Usar almacenamiento de objetos (por ejemplo, S3) en producción.
