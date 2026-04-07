# =========================================================================
# MULTI-STAGE DOCKERFILE PARA FLUTTER WEB
# =========================================================================
# Este Dockerfile utiliza un enfoque "Multi-stage" (múltiples etapas) para 
# separar el entorno de construcción pesado del entorno de ejecución ligero.
# 
# Beneficios:
# 1. Menor tamaño final de la imagen (solo se envía el código compilado, no las herramientas).
# 2. Mayor seguridad (no hay SDKs ni herramientas de compilación en el contenedor en producción).
# 3. Mejor uso de caché de capas en Docker.
# =========================================================================

# -------------------------------------------------------------------------
# ETAPA 1: BUILDER (Construcción)
# -------------------------------------------------------------------------
# Utilizamos una imagen de Ubuntu para tener las herramientas necesarias
# para descargar e instalar el SDK de Flutter.
FROM ubuntu:20.04 AS builder

# Evitamos interacciones manuales durante la instalación de paquetes (ej. zona horaria)
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalamos las dependencias necesarias para Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa

# 2. Descargamos el SDK de Flutter desde GitHub y lo colocamos en /usr/local
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# 3. Añadimos Flutter al PATH para poder usar el comando `flutter`
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# 4. Configuramos Flutter para web y cambiamos a la rama estable
RUN flutter channel stable
RUN flutter config --enable-web

# 5. Establecemos el directorio de trabajo donde colocaremos nuestro código
WORKDIR /app

# 6. Copiamos todo el código fuente del frontend al contenedor
COPY . .

# 7. Descargamos las dependencias del proyecto Flutter (equivalente a npm install)
RUN flutter pub get

# 8. Compilamos la aplicación para web en modo release (optimizado)
RUN flutter build web --release

# -------------------------------------------------------------------------
# ETAPA 2: RUNTIME (Servidor Web)
# -------------------------------------------------------------------------
# Para servir los archivos estáticos de Flutter Web, usamos Nginx.
# La versión "alpine" es extremadamente ligera y segura.
FROM nginx:alpine

# 9. Copiamos ÚNICAMENTE los archivos estáticos compilados de la etapa anterior ("builder").
# Todo lo demás (el SDK de Flutter, código fuente original, herramientas) se descarta.
COPY --from=builder /app/build/web /usr/share/nginx/html

# 10. Exponemos el puerto 80 donde Nginx servirá la web
EXPOSE 80

# 11. Comando por defecto para iniciar Nginx y mantenerlo en primer plano
CMD ["nginx", "-g", "daemon off;"]
