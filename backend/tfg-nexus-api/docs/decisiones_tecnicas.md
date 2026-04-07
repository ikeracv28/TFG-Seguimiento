# Nexus-API: Bitácora de Decisiones y Arquitectura

Este documento resume por qué he tomado ciertas decisiones técnicas durante el desarrollo del backend.

## 1. Stack Tecnológico

He elegido Java 21 junto con Spring Boot 3.4.1. Aunque Java 17 es muy estable, quería probar las nuevas funcionalidades de la versión 21 como los Records para los DTOs, que simplifican mucho el código de transporte de datos.

Para la persistencia, PostgreSQL es la base de datos que mejor manejo y me garantiza que las relaciones (Foreign Keys) se respeten al 100%, algo vital en un sistema con tantos perfiles como este.

## 2. Gestión del Esquema (Flyway)

En lugar de dejar que Hibernate cree las tablas automáticamente (que a veces genera nombres de columnas raros), uso Flyway. Esto me permite escribir mi propio SQL y tener un historial claro de cómo ha evolucionado la base de datos. Por ejemplo, en el script `V1` tuve que cambiar la estructura de tutores para separar el del centro del de la empresa.

## 3. Seguridad (JWT)

Como la aplicación tendrá un cliente Flutter, el uso de sesiones de servidor no era buena idea. He implementado JWT para que el servidor no tenga que guardar estado. El filtro de seguridad (`JwtAuthenticationFilter`) se encarga de interceptar cada petición y validar el token.

## 4. Mapeo de Datos (MapStruct)

Para no estar haciendo `new Dto()` y `setters` a mano en cada servicio, uso MapStruct. Es mucho más limpio y genera el código de mapeo en tiempo de compilación.

## 5. Manejo de Errores

He creado un `GlobalExceptionHandler` para que todos los errores de la API devuelvan el mismo formato JSON. Esto me facilitará mucho el trabajo en el frontend con Flutter para mostrar mensajes de error claros al usuario.

---
*Iker Acevedo - Abril 2026*
