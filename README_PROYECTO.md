# Nexus TFG - Sistema de Gestión de Prácticas Académicas

Nexus es una plataforma para centralizar el seguimiento de las prácticas FCT y FP Dual. Este repositorio contiene el código fuente del Backend (Spring Boot) y del Frontend (Flutter).

## 🚀 Inicio Rápido

### Requisitos previos
*   Java 21 (LTS)
*   PostgreSQL 15+
*   Maven 3.9+
*   Flutter 3.10+

### Configuración del Backend
1. Ir al directorio `backend/tfg-nexus-api/`.
2. Configurar las credenciales de la BBDD en `src/main/resources/application.properties` (o usar variables de entorno).
3. Ejecutar `./mvnw spring-boot:run`. Flyway se encargará de crear las tablas automáticamente.

### Configuración del Frontend
1. Ir al directorio `frontend/`.
2. Ejecutar `flutter pub get` para instalar las dependencias.
3. Lanzar la aplicación con `flutter run`.

## 📁 Estructura del Proyecto

*   `backend/`: API REST desarrollada con Spring Boot 3.
*   `frontend/`: Aplicación cliente desarrollada con Flutter.
*   `docker/`: Archivos para el despliegue mediante contenedores (en progreso).
*   `ARQUITECTURA_API.md`: Documentación de los endpoints y el contrato de datos.

## 🛠️ Tecnologías Principales
*   **Backend:** Java 21, Spring Boot, Spring Security (JWT), Hibernate, Flyway, MapStruct.
*   **Frontend:** Flutter, Dart, Provider (Estado).
*   **Base de Datos:** PostgreSQL.

---
