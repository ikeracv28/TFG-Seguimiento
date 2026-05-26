# =========================================================================
# MULTI-STAGE DOCKERFILE PARA FLUTTER WEB
# =========================================================================

# -------------------------------------------------------------------------
# ETAPA 1: BUILDER
# -------------------------------------------------------------------------
# Imagen pre-compilada con Flutter + Dart SDK. Evita clonar el repositorio
# de Flutter (~2 GB) en cada build, reduciendo el tiempo de ~20 min a ~3 min.
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Permite invalidar el caché del código fuente sin re-descargar Flutter
ARG CACHE_DATE=default
# URL del backend — inyectada en tiempo de compilación vía --dart-define
ARG API_URL=http://localhost:8080/api/v1

COPY . .
RUN flutter pub get
RUN flutter build web --release --dart-define=API_URL=$API_URL

# -------------------------------------------------------------------------
# ETAPA 2: RUNTIME (Servidor Nginx)
# -------------------------------------------------------------------------
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Valores por defecto para desarrollo local (sobrescribir en producción)
ENV API_ORIGIN=http://localhost:8080
ENV WS_ORIGIN=ws://localhost:8080

EXPOSE 80

# envsubst reemplaza solo las dos variables propias; deja $uri y demás intactos
CMD ["/bin/sh", "-c", "envsubst '${API_ORIGIN} ${WS_ORIGIN}' < /etc/nginx/nginx.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
