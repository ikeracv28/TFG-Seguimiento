# Usuarios de prueba — Nexus TFG

URL local: **http://localhost:3000** (Flutter web vía Nginx)

**Contraseña única para todos los usuarios: `Demo@Nexus2026`**

---

## Usuarios para el vídeo de demo

| Rol | Email | Nombre |
|-----|-------|--------|
| ADMIN | `fuencisla@nexus.edu` | Fuencisla López García |
| ALUMNO | `iker.acevedo@nexus.edu` | Iker Acevedo Donate |
| TUTOR_CENTRO | `david.valbuena@nexus.edu` | David Valbuena Segura |
| TUTOR_EMPRESA | `elena.torres@nexus.edu` | Elena Torres Sandoval *(Verisure, tutora de Iker)* |

---

## Todos los alumnos

| Email | Nombre | DNI | Práctica | Empresa |
|-------|--------|-----|----------|---------|
| `iker.acevedo@nexus.edu` | Iker Acevedo Donate | 11223344K | FCT-2026-001 | Verisure España S.L. |
| `iris.perez@nexus.edu` | Iris Pérez Aparicio | 22334455L | FCT-2026-002 | Verisure España S.L. |
| `rafael.medina@nexus.edu` | Rafael Medina Ayuso | 33445566M | FCT-2026-003 | Indra Sistemas S.A. |
| `marcos.perez@nexus.edu` | Marcos Pérez García | 44556677N | FCT-2026-004 | Verisure España S.L. |
| `alejandro.tovar@nexus.edu` | Alejandro Tovar Barroso | 55667788P | FCT-2026-005 | Deloitte España S.L. |
| `natalia.fuentes@nexus.edu` | Natalia Fuentes Molina | 66778899Q | FCT-2026-006 | Deloitte España S.L. |
| `daniel.herrera@nexus.edu` | Daniel Herrera Ponce | 77889900R | FCT-2026-007 | Telefónica S.A. |
| `carmen.alonso@nexus.edu` | Carmen Alonso Vidal | 88990011S | FCT-2026-008 | Telefónica S.A. |

---

## Todos los tutores de centro

| Email | Nombre | DNI | Alumnos asignados |
|-------|--------|-----|-------------------|
| `david.valbuena@nexus.edu` | David Valbuena Segura | 21212121B | Iker, Iris, Rafael |
| `fj.camarero@nexus.edu` | Francisco Javier Camarero Moles | 32323232C | Marcos, Alejandro |
| `javier.gordillo@nexus.edu` | Javier Gordillo Pintos | 43434343D | Natalia, Daniel |
| `ramses.munoz@nexus.edu` | Ramses Muñoz Herrera | 54545454E | Carmen |

---

## Todos los tutores de empresa

| Email | Nombre | DNI | Empresa |
|-------|--------|-----|---------|
| `elena.torres@nexus.edu` | Elena Torres Sandoval | 65656565F | Verisure España S.L. *(Iker, Iris, Marcos)* |
| `miguel.ruiz@nexus.edu` | Miguel Ángel Ruiz Fernández | 76767676G | Indra Sistemas S.A. *(Rafael, Alejandro)* |
| `sofia.dominguez@nexus.edu` | Sofía Domínguez Varela | 87878787H | Deloitte España S.L. *(Natalia)* |
| `carlos.bermejo@nexus.edu` | Carlos Bermejo Sánchez | 98989898I | Telefónica S.A. *(Daniel, Carmen)* |

---

## Empresas

| Nombre | CIF | Dirección |
|--------|-----|-----------|
| Verisure España S.L. | B82345678 | Calle Rosario Pino 14-16, Madrid |
| Indra Sistemas S.A. | A28599336 | Avenida de Bruselas 35, Alcobendas |
| Deloitte España S.L. | B82982609 | Plaza Pablo Ruiz Picasso 1, Madrid |
| Telefónica S.A. | A82018474 | Gran Vía 28, Madrid |

---

## Prácticas

| Código | Alumno | Tutor Centro | Tutor Empresa | Empresa | Horas | Estado |
|--------|--------|-------------|--------------|---------|-------|--------|
| FCT-2026-001 | Iker Acevedo | David Valbuena | Elena Torres | Verisure | 400 | ACTIVA |
| FCT-2026-002 | Iris Pérez | David Valbuena | Elena Torres | Verisure | 400 | ACTIVA |
| FCT-2026-003 | Rafael Medina | David Valbuena | Miguel Ruiz | Indra | 400 | ACTIVA |
| FCT-2026-004 | Marcos Pérez | FJ Camarero | Elena Torres | Verisure | 400 | ACTIVA |
| FCT-2026-005 | Alejandro Tovar | FJ Camarero | Sofía Domínguez | Deloitte | 400 | ACTIVA |
| FCT-2026-006 | Natalia Fuentes | Javier Gordillo | Sofía Domínguez | Deloitte | 400 | ACTIVA |
| FCT-2026-007 | Daniel Herrera | Javier Gordillo | Carlos Bermejo | Telefónica | 400 | ACTIVA |
| FCT-2026-008 | Carmen Alonso | Ramses Muñoz | Carlos Bermejo | Telefónica | 400 | ACTIVA |

---

## Estado de los datos de Iker (FCT-2026-001) para el vídeo

| Semana | Estado | Descripción breve |
|--------|--------|-------------------|
| 20/01 | COMPLETADO | Onboarding Verisure |
| 27/01 | COMPLETADO | Sistemas de alarma |
| 03/02 | COMPLETADO | Módulo gestión alertas |
| 10/02 | COMPLETADO | Integración CRM |
| 17/02 | COMPLETADO | Refactorización reportes |
| 24/02 | PENDIENTE_CENTRO | Panel monitorización Angular |
| 03/03 | PENDIENTE_EMPRESA | Notificaciones push Firebase |

- 2 ausencias justificadas (05/02 y 26/02)
- 1 incidencia abierta (acceso a repositorio privado)
- Evaluación final: **pendiente** ← se puede demostrar en el vídeo

---

## Notas técnicas

- Contraseña única `Demo@Nexus2026` cumple política OWASP A02 (mayúscula, minúscula, número, símbolo, 14 caracteres).
- Hashes BCrypt cost=10 generados en migración V21.
- Para reproducir la BD desde cero: `docker rm -f nexus-db` + `docker-compose up -d` (Flyway aplica V1–V21 automáticamente).
- Para **volver al estado anterior** (datos de prueba originales): eliminar `V21__Demo_Realista.sql` y ejecutar lo mismo.
