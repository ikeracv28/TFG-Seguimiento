# ARQUITECTURA_API.md — Contrato REST de Nexus
# Última actualización: 19/04/2026 (Hito 2 — navegación Flutter + POST incidencias)
# Base URL: http://localhost:8080/api/v1

---

## Convenciones

- Todos los endpoints requieren cabecera `Authorization: Bearer <JWT>` salvo los de autenticación.
- Respuestas de error siguen el formato `{ "mensaje": "...", "timestamp": "..." }`.
- Los estados de prácticas y seguimientos son cadenas en mayúsculas (sin enum en la API).
- Paginación: los endpoints de lista admin usan `?page=0&size=20&sort=fechaCreacion,desc`.

---

## A. Autenticación

### POST /auth/register
**Acceso**: público
**Body**: `{ "dni", "nombre", "apellidos", "email", "password" }`
**Respuesta 201**: `{ "token", "tipo", "id", "email", "nombre", "apellidos", "roles" }`

### POST /auth/login
**Acceso**: público
**Body**: `{ "email", "password" }`
**Respuesta 200**: `{ "token", "tipo", "id", "email", "nombre", "apellidos", "roles" }`

---

## B. Prácticas

### GET /practicas
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA
**Query params**: `page`, `size`, `sort` (paginado)
**Respuesta 200**: `Page<PracticaResponse>`

### GET /practicas/me
**Acceso**: ALUMNO
**Descripción**: Devuelve la práctica ACTIVA del alumno autenticado (identificado por JWT).
**Respuesta 200**: `PracticaResponse`
**Respuesta 404**: si el alumno no tiene práctica activa

### GET /practicas/{id}
**Acceso**: cualquier usuario autenticado
**Respuesta 200**: `PracticaResponse`

### GET /practicas/alumno/{alumnoId}
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA o el propio alumno si #alumnoId == su id
**Respuesta 200**: `List<PracticaResponse>`

### POST /practicas
**Acceso**: ADMIN
**Body**: `PracticaRequest { codigo, alumnoId, tutorCentroId, tutorEmpresaId, empresaId, fechaInicio, fechaFin, horasTotales, estado }`
**Respuesta 201**: `PracticaResponse`

### PUT /practicas/{id}
**Acceso**: ADMIN, TUTOR_CENTRO
**Body**: `PracticaRequest`
**Respuesta 200**: `PracticaResponse`

### DELETE /practicas/{id}
**Acceso**: ADMIN
**Regla**: solo se puede eliminar si estado == BORRADOR
**Respuesta 204**

### PATCH /practicas/{id}/estado
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA
**Query**: `nuevoEstado=ACTIVA|FINALIZADA|BORRADOR`
**Respuesta 200**: `PracticaResponse`

---

## C. Seguimientos

### GET /seguimientos/practica/{practicaId}
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA, ALUMNO
**Respuesta 200**: `List<SeguimientoResponse>`
```json
{
  "id": 1,
  "practicaId": 1,
  "fechaRegistro": "2025-04-07",
  "horasRealizadas": 8,
  "descripcion": "Texto...",
  "estado": "COMPLETADO",
  "validadoPorId": null,
  "validadoPorNombre": null,
  "comentarioTutor": null,
  "fechaCreacion": "2026-04-19T13:56:12"
}
```

**Estados posibles**: `PENDIENTE`, `VALIDADO`, `COMPLETADO`, `RECHAZADO`
> Nota: en el Hito 3 los estados pasarán a: `PENDIENTE_EMPRESA`, `PENDIENTE_CENTRO`, `COMPLETADO`, `RECHAZADO`

### POST /seguimientos
**Acceso**: ALUMNO
**Body**: `SeguimientoRequest { practicaId, fechaRegistro, horasRealizadas, descripcion }`
**Respuesta 201**: `SeguimientoResponse`

### PATCH /seguimientos/{id}/validar
**Acceso**: TUTOR_CENTRO, TUTOR_EMPRESA
**Query**: `nuevoEstado=VALIDADO|RECHAZADO`, `comentario` (opcional)
**Respuesta 200**: `SeguimientoResponse`
> Este endpoint se dividirá en Hito 3 en `/validar-empresa` y `/validar-centro`

### DELETE /seguimientos/{id}
**Acceso**: ALUMNO
**Regla**: solo eliminable si estado == PENDIENTE
**Respuesta 204**

---

## D. Incidencias

### GET /incidencias/practica/{practicaId}
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA, ALUMNO
**Descripción**: Lista de incidencias de una práctica, ordenadas por fecha descendente.
**Respuesta 200**: `List<IncidenciaResponse>`
```json
{
  "id": 1,
  "practicaId": 1,
  "creadaPorId": 3,
  "creadaPorNombre": "Estudiante Pruebas",
  "tipo": "ACCESO",
  "descripcion": "El alumno no tiene acceso al repositorio...",
  "estado": "ABIERTA",
  "fechaCreacion": "2026-04-19T13:56:12"
}
```

**Tipos posibles**: `ACCESO`, `AUSENCIA`, `COMPORTAMIENTO`, `ACCIDENTE`, `OTROS`
**Estados posibles**: `ABIERTA`, `EN_PROCESO`, `RESUELTA`, `CERRADA`

### GET /incidencias/{id}
**Acceso**: cualquier usuario autenticado
**Respuesta 200**: `IncidenciaResponse`

### POST /incidencias
**Acceso**: ALUMNO, TUTOR_CENTRO, TUTOR_EMPRESA
**Descripción**: Reporta una nueva incidencia vinculada a la práctica ACTIVA del usuario autenticado. El alumno no necesita indicar el ID de práctica; el backend lo resuelve desde el JWT.
**Body**: `IncidenciaRequest { tipo, descripcion }`
**Tipos válidos**: `ACCESO`, `AUSENCIA`, `COMPORTAMIENTO`, `ACCIDENTE`, `OTROS`
**Validación**: `descripcion` entre 10 y 1000 caracteres.
**Respuesta 201**: `IncidenciaResponse` con `estado: "ABIERTA"`
**Respuesta 400**: si la descripción no cumple las validaciones
**Respuesta 409**: si el usuario no tiene práctica activa

> **Pendiente Hito 3**: `PATCH /incidencias/{id}/estado` — gestión de resolución por tutor centro

---

## E. Usuarios

### GET /usuarios
**Acceso**: ADMIN
**Respuesta 200**: `List<UsuarioResponse>`

### GET /usuarios/{id}
**Acceso**: ADMIN o el propio usuario
**Respuesta 200**: `UsuarioResponse`

### PUT /usuarios/{id}
**Acceso**: ADMIN
**Respuesta 200**: `UsuarioResponse`

---

## F. Empresas y Centros

### GET /empresas
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA
**Respuesta 200**: `List<EmpresaResponse>`

### POST /empresas
**Acceso**: ADMIN
**Respuesta 201**: `EmpresaResponse`

### GET /centros
**Acceso**: cualquier usuario autenticado
**Respuesta 200**: `List<CentroResponse>`

---

## G. Pendiente (Hito 3)

| Endpoint | Descripción |
|----------|-------------|
| ~~`POST /incidencias`~~ | ~~El alumno reporta una incidencia desde la app~~ — **Implementado 19/04/2026** |
| `PATCH /incidencias/{id}/estado` | Tutor centro actualiza estado de incidencia |
| `PATCH /seguimientos/{id}/validar-empresa` | Primera validación (TUTOR_EMPRESA) |
| `PATCH /seguimientos/{id}/validar-centro` | Segunda validación (TUTOR_CENTRO) |
| `GET /mensajes/practica/{id}` | Historial de chat |
| `POST /mensajes` | Enviar mensaje (REST pre-WebSocket) |
| `WS /ws/chat/{practicaId}` | Canal WebSocket/STOMP en tiempo real |

---

## Usuarios de prueba (migración V3 + V4)

| Email | Contraseña | Rol |
|-------|-----------|-----|
| admin@nexus.edu | admin123 | ROLE_ADMIN |
| tutor@nexus.edu | 123456 | ROLE_TUTOR_CENTRO |
| tutorempresa@nexus.edu | 123456 | ROLE_TUTOR_EMPRESA |
| alumno@nexus.edu | 123456 | ROLE_ALUMNO |
