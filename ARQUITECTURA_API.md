# ARQUITECTURA_API.md — Contrato REST de Nexus
# Última actualización: 01/05/2026 (Hito 3 completo)
# Base URL: http://localhost:8080/api/v1

---

## Convenciones

- Todos los endpoints requieren cabecera `Authorization: Bearer <JWT>` salvo los de autenticación.
- Respuestas de error: `{ "status": 400|403|404|409|500, "message": "...", "timestamp": "...", "errors": null|{} }`
- Los estados de prácticas y seguimientos son cadenas en mayúsculas.
- Paginación: los endpoints de lista admin usan `?page=0&size=20&sort=fechaCreacion,desc`.

---

## A. Autenticación

### POST /auth/register
**Acceso**: público
**Body**: `{ "dni", "nombre", "apellidos", "email", "password" }`
**Respuesta 201**: `{ "token", "tipo", "id", "email", "nombre", "apellidos", "roles" }`
**Respuesta 400**: validación de campos fallida
**Respuesta 409**: email o DNI ya registrados (mensaje genérico, sin revelar cuál)

### POST /auth/login
**Acceso**: público
**Body**: `{ "email", "password" }`
**Respuesta 200**: `{ "token", "tipo", "id", "email", "nombre", "apellidos", "roles" }`
**Respuesta 401**: credenciales inválidas
**Nota**: limitado a 10 peticiones/minuto por IP (RateLimitFilter, HTTP 429 si supera)

### POST /auth/logout
**Acceso**: cualquier usuario autenticado (`isAuthenticated()`)
**Header**: `Authorization: Bearer <token>`
**Descripción**: invalida el JTI del token en la blacklist del servidor. El token queda inválido aunque no haya expirado.
**Respuesta 204**: logout correcto
**Respuesta 403**: token no presente o inválido

---

## B. Prácticas

### GET /practicas
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA
**Query params**: `page`, `size`, `sort` (paginado, default size=20)
**Respuesta 200**: `Page<PracticaResponse>`

### GET /practicas/me
**Acceso**: ALUMNO
**Descripción**: devuelve la práctica ACTIVA del alumno identificado por el JWT. Sin parámetros.
**Respuesta 200**: `PracticaResponse`
**Respuesta 404**: el alumno no tiene práctica activa

### GET /practicas/tutor-empresa/me
**Acceso**: TUTOR_EMPRESA
**Descripción**: lista las prácticas donde el tutor de empresa autenticado está asignado.
**Respuesta 200**: `List<PracticaResponse>`

### GET /practicas/tutor-centro/me
**Acceso**: TUTOR_CENTRO
**Descripción**: lista las prácticas donde el tutor del centro autenticado está asignado.
**Respuesta 200**: `List<PracticaResponse>`

### GET /practicas/{id}
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA — o el alumno/tutor que sea participante directo de esa práctica (`@practicaService.esParticipante`)
**Respuesta 200**: `PracticaResponse`
**Respuesta 403**: usuario autenticado que no es participante
**Nota IDOR**: el check SpEL verifica participación real, no solo rol. Testado con A01AccessControlTest (8/8).

### GET /practicas/alumno/{alumnoId}
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA — o el propio alumno si `alumnoId` coincide con su cuenta (`@practicaService.perteneceAlAlumnoAutenticado`)
**Respuesta 200**: `List<PracticaResponse>`
**Respuesta 403**: alumno que intenta ver prácticas de otro alumno

### POST /practicas
**Acceso**: ADMIN
**Body**:
```json
{
  "codigo": "FCT-2025-001",
  "alumnoId": 3,
  "tutorCentroId": 2,
  "tutorEmpresaId": 4,
  "empresaId": 1,
  "fechaInicio": "2025-04-07",
  "fechaFin": "2025-11-07",
  "horasTotales": 240,
  "estado": "BORRADOR"
}
```
**Respuesta 201**: `PracticaResponse`
**Respuesta 409**: código de práctica ya existe

### PUT /practicas/{id}
**Acceso**: ADMIN, TUTOR_CENTRO
**Body**: `PracticaRequest` (mismos campos que POST)
**Respuesta 200**: `PracticaResponse`

### DELETE /practicas/{id}
**Acceso**: ADMIN
**Regla de negocio**: solo eliminable si `estado == BORRADOR`
**Respuesta 204**
**Respuesta 409**: práctica en estado ACTIVA o FINALIZADA

### PATCH /practicas/{id}/estado
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA
**Query**: `nuevoEstado=BORRADOR|ACTIVA|FINALIZADA`
**Respuesta 200**: `PracticaResponse`
**Respuesta 409**: estado no válido

---

## C. Seguimientos (Partes de trabajo)

### POST /seguimientos
**Acceso**: ALUMNO
**Body**:
```json
{
  "practicaId": 1,
  "fechaRegistro": "2025-04-14",
  "horasRealizadas": 8,
  "descripcion": "Descripción de las actividades realizadas..."
}
```
**Respuesta 201**: `SeguimientoResponse` con `estado: "PENDIENTE_EMPRESA"`

### GET /seguimientos/practica/{practicaId}
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA, ALUMNO
**Respuesta 200**: `List<SeguimientoResponse>`
```json
{
  "id": 1,
  "practicaId": 1,
  "fechaRegistro": "2025-04-14",
  "horasRealizadas": 8,
  "descripcion": "...",
  "estado": "COMPLETADO",
  "validadoPorId": 2,
  "validadoPorNombre": "Nombre Tutor",
  "comentarioTutor": null,
  "fechaCreacion": "2026-04-19T13:56:12"
}
```

**Estados posibles**:
| Estado | Significado |
|--------|-------------|
| `PENDIENTE_EMPRESA` | Alumno registró el parte. Pendiente firma del tutor de empresa. |
| `PENDIENTE_CENTRO` | Tutor de empresa aprobó. Pendiente visto bueno del tutor del centro. |
| `COMPLETADO` | Ambos tutores validaron. Horas contabilizadas en el progreso del alumno. |
| `RECHAZADO` | Tutor de empresa rechazó. Se genera `Incidencia` tipo `RECHAZO_PARTE` automáticamente. |

### PATCH /seguimientos/{id}/validar-empresa
**Acceso**: TUTOR_EMPRESA
**Query**: `nuevoEstado=PENDIENTE_CENTRO|RECHAZADO`, `motivo` (obligatorio si RECHAZADO)
**Respuesta 200**: `SeguimientoResponse`
**Respuesta 409**: parte no está en estado `PENDIENTE_EMPRESA`
**Efecto secundario**: si RECHAZADO, crea automáticamente una `Incidencia` de tipo `RECHAZO_PARTE`.

### PATCH /seguimientos/{id}/validar-centro
**Acceso**: TUTOR_CENTRO
**Sin parámetros**: siempre transiciona a `COMPLETADO`
**Respuesta 200**: `SeguimientoResponse`
**Respuesta 409**: parte no está en estado `PENDIENTE_CENTRO` (orden empresa→centro inviolable)

### DELETE /seguimientos/{id}
**Acceso**: ALUMNO
**Regla de negocio**: solo eliminable si `estado == PENDIENTE_EMPRESA`
**Respuesta 204**

---

## D. Incidencias

### POST /incidencias
**Acceso**: ALUMNO, TUTOR_CENTRO, TUTOR_EMPRESA
**Descripción**: el backend resuelve el ID de práctica desde el JWT del usuario autenticado.
**Body**:
```json
{
  "tipo": "ACCESO",
  "descripcion": "El alumno no tiene acceso al repositorio del proyecto."
}
```
**Tipos válidos**: `ACCESO`, `AUSENCIA`, `COMPORTAMIENTO`, `ACCIDENTE`, `OTROS`
> `RECHAZO_PARTE` se genera solo automáticamente al rechazar un seguimiento, no por este endpoint.

**Validación**: `descripcion` entre 10 y 1000 caracteres.
**Respuesta 201**: `IncidenciaResponse` con `estado: "ABIERTA"`
**Respuesta 409**: el usuario autenticado no tiene práctica activa

### GET /incidencias/practica/{practicaId}
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA, ALUMNO
**Respuesta 200**: `List<IncidenciaResponse>` ordenadas por fecha descendente
```json
{
  "id": 1,
  "practicaId": 1,
  "creadaPorId": 3,
  "creadaPorNombre": "Carlos Pérez Moreno",
  "tipo": "OTROS",
  "descripcion": "...",
  "estado": "ABIERTA",
  "fechaCreacion": "2026-04-19T13:56:12"
}
```

**Estados posibles**: `ABIERTA` → `EN_PROCESO` → `RESUELTA` → `CERRADA`

### GET /incidencias/{id}
**Acceso**: cualquier usuario autenticado
**Respuesta 200**: `IncidenciaResponse`

### PATCH /incidencias/{id}/estado
**Acceso**: TUTOR_CENTRO
**Query**: `nuevoEstado=EN_PROCESO|RESUELTA|CERRADA`
**Descripción**: avanza el estado de resolución. No permite retroceder. Al llegar a `RESUELTA` o `CERRADA` registra la fecha de resolución.
**Respuesta 200**: `IncidenciaResponse`
**Respuesta 409**: transición de estado inválida o incidencia ya `CERRADA`

---

## E. Perfil de usuario

### GET /usuarios/me
**Acceso**: cualquier usuario autenticado
**Descripción**: devuelve el perfil del usuario autenticado por JWT. Sin parámetros.
**Respuesta 200**: `UsuarioResponse`

---

## F. Administración de usuarios (ADMIN)

> Todos los endpoints de este bloque requieren rol ADMIN.

### GET /admin/usuarios
**Respuesta 200**: `List<UsuarioResponse>` — todos los usuarios registrados

### POST /admin/usuarios
**Body**:
```json
{
  "dni": "12345678A",
  "nombre": "Nombre",
  "apellidos": "Apellidos",
  "email": "usuario@nexus.edu",
  "password": "Pass@word1234",
  "rolNombre": "ROLE_ALUMNO"
}
```
**Roles válidos**: `ROLE_ALUMNO`, `ROLE_TUTOR_CENTRO`, `ROLE_TUTOR_EMPRESA`, `ROLE_ADMIN`
**Respuesta 201**: `UsuarioResponse`
**Respuesta 409**: email o DNI ya existentes

### PATCH /admin/usuarios/{id}/toggle-activo
**Descripción**: activa o desactiva la cuenta del usuario (toggle). Un usuario inactivo no puede autenticarse.
**Respuesta 200**: `UsuarioResponse` con el nuevo estado `activo`

---

## G. Empresas y Centros

### GET /empresas
**Acceso**: cualquier usuario autenticado
**Respuesta 200**: `List<EmpresaResponse>`

### GET /centros
**Acceso**: cualquier usuario autenticado
**Respuesta 200**: `List<CentroResponse>`

---

## H. Ausencias

> **Implementado Hito 4 (01/05/2026).** V8 Flyway migration, justificante en bytea (PDF/JPG/PNG ≤5 MB).

### POST /ausencias
**Acceso**: ALUMNO
**Body**:
```json
{
  "practicaId": 1,
  "fecha": "2025-04-22",
  "motivo": "Cita médica — parte de baja adjunta."
}
```
**Respuesta 201**: `AusenciaResponse` con `tipo: "PENDIENTE"`
**Respuesta 403**: el alumno no es propietario de esa práctica
**Respuesta 409**: ya existe una ausencia registrada para esa fecha en esa práctica

### GET /ausencias/practica/{practicaId}
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA, ALUMNO
**Respuesta 200**: `List<AusenciaResponse>` ordenadas por fecha descendente

### GET /ausencias/{id}
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA, ALUMNO
**Respuesta 200**: `AusenciaResponse`

### GET /ausencias/{id}/justificante
**Acceso**: ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA, ALUMNO
**Respuesta 200**: bytes del fichero con `Content-Type` original y `Content-Disposition: inline`
**Respuesta 404**: la ausencia no tiene justificante adjunto

### PATCH /ausencias/{id}/revisar
**Acceso**: TUTOR_EMPRESA (ownership check — solo si supervisa esa práctica)
**Query**: `nuevoTipo=JUSTIFICADA|INJUSTIFICADA`, `comentario` (opcional)
**Respuesta 200**: `AusenciaResponse` con el nuevo tipo
**Respuesta 403**: el tutor empresa no supervisa esa práctica (OWASP A01)
**Respuesta 409**: la ausencia ya fue revisada

### PATCH /ausencias/{id}/justificante
**Acceso**: ALUMNO (solo el que registró la ausencia)
**Content-Type**: `multipart/form-data`
**Field**: `fichero` (PDF, JPG o PNG, ≤5 MB)
**Respuesta 200**: `AusenciaResponse` con `tieneJustificante: true`
**Respuesta 409**: ausencia ya revisada — no se permite modificar

### DELETE /ausencias/{id}
**Acceso**: ALUMNO (solo el que registró la ausencia)
**Regla de negocio**: solo eliminable si `tipo == PENDIENTE`
**Respuesta 204**

**Estados posibles**:
| Tipo | Significado |
|------|-------------|
| `PENDIENTE` | Registrada por el alumno, sin revisar. |
| `JUSTIFICADA` | Revisada por el tutor de empresa — documentada y aceptada. |
| `INJUSTIFICADA` | Revisada por el tutor de empresa — no aceptada o sin justificación válida. |

**Response example**:
```json
{
  "id": 1,
  "practicaId": 1,
  "fecha": "2025-04-22",
  "motivo": "Cita médica — parte de baja adjunta.",
  "tipo": "PENDIENTE",
  "tieneJustificante": false,
  "nombreFichero": null,
  "registradaPorId": 3,
  "registradaPorNombre": "Carlos Pérez Moreno",
  "revisadaPorId": null,
  "revisadaPorNombre": null,
  "comentarioRevision": null,
  "fechaCreacion": "2026-05-01T14:00:00"
}
```

---

## I. Pendiente (Hito 4 — 19 mayo 2026)

| Endpoint | Descripción |
|----------|-------------|
| `GET /mensajes/practica/{id}` | Historial de mensajes del chat |
| `POST /mensajes` | Enviar mensaje (REST) |
| `WS /ws/chat/{practicaId}` | Canal WebSocket/STOMP en tiempo real |

---

## Usuarios de prueba

### Originales (V1–V6)

| Email | Contraseña | Rol |
|-------|-----------|-----|
| admin@nexus.edu | `Admin@Nexus2026` | ROLE_ADMIN |
| tutor@nexus.edu | `Tutor@Nexus2026` | ROLE_TUTOR_CENTRO |
| tutorempresa@nexus.edu | `Empresa@Nexus2026` | ROLE_TUTOR_EMPRESA |
| alumno@nexus.edu | `Alumno@Nexus2026` | ROLE_ALUMNO |

### Demo Hito 3 (V7) — contraseña: `Prueba@Nexus2026`

| Email | Nombre | Rol | Práctica |
|-------|--------|-----|----------|
| tutor2@nexus.edu | Ana Martínez Vega | ROLE_TUTOR_CENTRO | FCT-2025-003, FCT-2025-004 |
| tutorempresa2@nexus.edu | María López Romero | ROLE_TUTOR_EMPRESA | FCT-2025-002, FCT-2025-004 |
| tutorempresa3@nexus.edu | Pedro Ruiz Navarro | ROLE_TUTOR_EMPRESA | FCT-2025-003 |
| alumno2@nexus.edu | Carlos Pérez Moreno | ROLE_ALUMNO | FCT-2025-002 (ACTIVA) |
| alumno3@nexus.edu | Laura García Blanco | ROLE_ALUMNO | FCT-2025-003 (BORRADOR) |
| alumno4@nexus.edu | Diego Sánchez Torres | ROLE_ALUMNO | FCT-2025-004 (FINALIZADA) |
