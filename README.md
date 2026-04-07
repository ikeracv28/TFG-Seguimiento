# Nexus TFG - Sistema de Gestión de Prácticas Académicas

Nexus es una plataforma centralizada para el seguimiento y gestión de prácticas de Formación en Centros de Trabajo (FCT) y FP Dual. Este repositorio integra tanto el **Backend** (Spring Boot) como el **Frontend** (Flutter).

## 🚀 Inicio Rápido

### Requisitos Previos
*   **Java 21 (LTS)**
*   **PostgreSQL 15+**
*   **Maven 3.9+**
*   **Flutter 3.10+**

### Configuración del Backend
1. Navega al directorio `backend/tfg-nexus-api/`.
2. Configura las credenciales de la base de datos en `src/main/resources/application.properties` o mediante variables de entorno en el archivo `.env`.
3. Ejecuta el comando `./mvnw spring-boot:run`. El sistema utilizará **Flyway** para generar la estructura de tablas automáticamente.

### Configuración del Frontend
1. Navega al directorio `frontend/`.
2. Ejecuta `flutter pub get` para descargar e instalar las dependencias necesarias.
3. Inicia la aplicación con el comando `flutter run`.

## 📁 Estructura del Proyecto

*   **`backend/`**: API REST robusta desarrollada con Spring Boot 3, siguiendo una arquitectura por capas.
*   **`frontend/`**: Aplicación multiplataforma (Android, iOS, Web, Desktop) desarrollada con Flutter.
*   **`docker/`**: Configuraciones de Docker y Docker Compose para el despliegue en contenedores.
*   **`ARQUITECTURA_API.md`**: Documentación detallada de los endpoints, modelos y el contrato de datos.

## 🛠️ Tecnologías Principales

*   **Backend:** Java 21, Spring Boot, Spring Security (JWT para autenticación), Hibernate/JPA, Flyway (migraciones), MapStruct (mapeo de DTOs).
*   **Frontend:** Flutter, Dart, Provider (gestión de estado), Retrofit/Dio (consumo de API).
*   **Base de Datos:** PostgreSQL.

---


## ⚙️ Backend (Spring Boot)
Este módulo se encarga de toda la lógica de negocio, la seguridad mediante tokens JWT y la persistencia de datos en PostgreSQL. Implementa un sistema de excepciones global para asegurar respuestas consistentes.

## 📱 Frontend (Flutter)
Interfaz de usuario moderna y adaptativa que permite a alumnos y tutores realizar el seguimiento diario de las horas de prácticas y la validación de actividades en tiempo real.
