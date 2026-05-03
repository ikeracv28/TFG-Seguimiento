# Usuarios de prueba — Nexus TFG

URL local: **http://localhost** (Flutter web vía Nginx)

---

## Usuarios principales (contraseña OWASP — V6)

| Rol | Email | Contraseña | Nombre | DNI |
|-----|-------|-----------|--------|-----|
| ALUMNO | `alumno@nexus.edu` | `Alumno@Nexus2026` | Pedro Alumno García | 33333333C |
| TUTOR_CENTRO | `tutor@nexus.edu` | `Tutor@Nexus2026` | Ana Tutor Martínez | 22222222B |
| TUTOR_EMPRESA | `tutorempresa@nexus.edu` | `Empresa@Nexus2026` | Carlos García Empresa | 44444444D |
| ADMIN | `admin@nexus.edu` | `Admin@Nexus2026` | Admin Nexus | 11111111A |

---

## Usuarios adicionales del Hito 3 — contraseña común: `Prueba@Nexus2026`

### Alumnos

| Email | Nombre | DNI |
|-------|--------|-----|
| `alumno2@nexus.edu` | Carlos Pérez Moreno | 88888888H |
| `alumno3@nexus.edu` | Laura García Blanco | 99999999I |
| `alumno4@nexus.edu` | Diego Sánchez Torres | 10101010J |

### Tutores de empresa

| Email | Nombre | DNI | Empresa |
|-------|--------|-----|---------|
| `tutorempresa2@nexus.edu` | María López Romero | 55555555E | InnovateTech S.A. |
| `tutorempresa3@nexus.edu` | Pedro Ruiz Navarro | 66666666F | DataSystems S.L. |

### Tutor de centro

| Email | Nombre | DNI |
|-------|--------|-----|
| `tutor2@nexus.edu` | Ana Martínez Vega | 77777777G |

---

## Prácticas de demo

| Código | Alumno | Tutor Centro | Tutor Empresa | Empresa | Horas | Estado |
|--------|--------|-------------|--------------|---------|-------|--------|
| `FCT-2025-001` | alumno | tutor | tutorempresa | EjemploTech S.L. | 240 | ACTIVA |
| `FCT-2025-002` | alumno2 | tutor | tutorempresa2 | InnovateTech S.A. | 240 | ACTIVA |
| `FCT-2025-003` | alumno3 | tutor2 | tutorempresa3 | DataSystems S.L. | 200 | BORRADOR |
| `FCT-2025-004` | alumno4 | tutor2 | tutorempresa2 | InnovateTech S.A. | 220 | FINALIZADA |

---

## Empresas

| Nombre | CIF | Ciudad |
|--------|-----|--------|
| EjemploTech S.L. | B12345678 | Madrid |
| InnovateTech S.A. | A87654321 | Barcelona |
| DataSystems S.L. | B98765432 | Valencia |

---

## Notas

- Contraseñas principales siguen política OWASP A02: 12+ caracteres, mayúscula, minúscula, número y símbolo.
- Contraseña de todos los usuarios del Hito 3: `Prueba@Nexus2026`
- Hashes BCrypt cost=10 almacenados en BD vía migraciones V3, V6 y V7.
- Para regenerar la BD desde cero: `docker rm -f nexus-db` + `docker-compose up -d` (Flyway aplica V1–V8 automáticamente).
- Este fichero está en `.gitignore` — no se sube al repositorio.
