# Arquitectura del Sistema: Java (Backend) vs Flutter (Frontend) y Contrato de APIs

Para mantener una separación de responsabilidades estricta y profesional en el Trabajo de Fin de Grado, el proyecto adopta una arquitectura Cliente-Servidor clásica mediante servicios RESTful sin estado (*Stateless*).

---

## 1. Responsabilidades de Java Spring Boot (El Servidor / Backend)
El backend actúa como el "cerebro" y único guardián de la persistencia de los datos. Desconoce por completo cómo se ven las pantallas.

*   **Exposición de API RESTful:** Define los endpoints (rutas web) que reciben peticiones y devuelven datos exclusivamente en formato JSON bajo el prefijo `/api/v1/`.
*   **Lógica de Negocio (Services):** Toma de decisiones y validaciones.
*   **Persistencia de Datos (JPA/Hibernate):** Mapeo de objetos Java a PostgreSQL.
*   **Seguridad (JWT):** Gestión de autenticación y roles.

## 2. Responsabilidades de Flutter (El Cliente / Frontend)
El frontend actúa como la interfaz interactiva. Su "verdad" proviene de consultar al backend.

*   **Renderizado de Interfaz (UI):** Construye las vistas mediante Widgets.
*   **Consumo de API:** Ejecuta peticiones HTTP inyectando el token JWT en las cabeceras.
*   **Gestión de Estado:** Almacenamiento temporal de datos (Provider/Riverpod) y del token (Secure Storage).

---

## 3. Contrato de APIs (Estado: Hito 1 - 25%)

### A. Autenticación y Usuarios (Implementado)
*   `POST /api/v1/auth/login`
    *   **Envía:** `{email, password}`.
    *   **Devuelve:** Token JWT y perfil básico.
*   `POST /api/v1/auth/register`
    *   **Envía:** `{dni, nombre, apellidos, email, password}`.
    *   **Devuelve:** Usuario registrado y su token.
*   `GET /api/v1/usuarios/me`
    *   **Requisito:** Token JWT.
    *   **Devuelve:** Perfil detallado del usuario logueado.

### B. Módulos Maestros (Implementado - Solo Lectura)
*   `GET /api/v1/centros`: Lista de institutos registrados.
*   `GET /api/v1/empresas`: Lista de empresas colaboradoras.

### C. Módulo de Prácticas Académicas (Diseño de Contrato - Hito 2)
*   `GET /api/v1/practicas`: Lista de prácticas filtrada por rol.
*   `POST /api/v1/practicas`: Creación de nueva práctica (Admin/Tutor Centro).
*   `PUT /api/v1/practicas/{id}/estado`: Cambio de estado (Aceptada, Finalizada, etc).

### D. Seguimiento y Comunicaciones (Diseño de Contrato - Hito 2)
*   `GET /api/v1/practicas/{id}/seguimientos`: Diario de seguimiento.
*   `POST /api/v1/practicas/{id}/incidencias`: Registro de problemas en la empresa.
*   `GET /api/v1/practicas/{id}/mensajes`: Chat interno entre tutores y alumno.

---
*(Nota: El contrato se irá implementando progresivamente según las pistas de desarrollo definidas en `conductor/tracks/`).*
