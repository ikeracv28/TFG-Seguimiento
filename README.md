[README.md](https://github.com/user-attachments/files/26867196/README.md)
<div align="center">

<img src="https://raw.githubusercontent.com/ikeracv28/Nexus-TFG/main/docs/logo.png" alt="Nexus Logo" width="120"/>

# NEXUS
### Sistema de Gestión de Prácticas Académicas FCT

**Trabajo de Fin de Grado · Iker Acevedo Donate · CampusFP**

---

[![Java](https://img.shields.io/badge/Java-21-orange?style=flat-square&logo=openjdk)](https://openjdk.org/projects/jdk/21/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.4.1-brightgreen?style=flat-square&logo=springboot)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-316192?style=flat-square&logo=postgresql)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

</div>

---

## ¿Qué es Nexus?

Nexus es una plataforma web y móvil que digitaliza y centraliza la gestión de las prácticas en empresa (FCT) de los ciclos formativos de FP. Elimina el caos de correos, excels y llamadas que sufren actualmente alumnos, tutores y centros educativos, y los reúne en un único entorno digital con seguimiento en tiempo real.

**El problema que resuelve:** El alumno está en la empresa, el tutor en el centro, y la comunicación entre ellos se pierde en cadenas de correos interminables. Los partes semanales se firman en papel y nadie sabe realmente cómo le va al alumno hasta que es demasiado tarde.

**La solución:** Un sistema con cuatro roles diferenciados (alumno, tutor de centro, tutor de empresa, administrador de centro), seguimiento diario con validación en dos fases, gestión de incidencias automática y chat interno por práctica.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                     NEXUS PLATFORM                       │
│                                                          │
│  ┌──────────────┐    REST/JWT    ┌──────────────────┐   │
│  │   Flutter    │ ─────────────► │   Spring Boot    │   │
│  │  (Web + App) │                │   API REST       │   │
│  │  Puerto 3000 │ ◄───────────── │   Puerto 8080    │   │
│  └──────────────┘                └────────┬─────────┘   │
│                                           │ JPA/Flyway  │
│                                  ┌────────▼─────────┐   │
│                                  │   PostgreSQL 15   │   │
│                                  │   Puerto 5432     │   │
│                                  └──────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Stack tecnológico

| Capa | Tecnología | Justificación |
|------|-----------|---------------|
| **Frontend** | Flutter + Dart | Una sola base de código para web, Android e iOS |
| **HTTP Client** | Dio + Interceptores JWT | Inyección automática del token en cada petición |
| **Estado** | Provider | Gestión de estado ligera y predecible |
| **Backend** | Spring Boot 3.4.1 + Java 21 | Rendimiento, seguridad y ecosistema maduro |
| **Seguridad** | JWT + BCrypt + @PreAuthorize | Autenticación stateless con autorización por método |
| **Base de datos** | PostgreSQL 15 | Robustez en relaciones complejas |
| **Migraciones** | Flyway | Historial versionado del esquema de BBDD |
| **Contenedores** | Docker + Docker Compose | Despliegue reproducible en cualquier entorno |

---

## Características principales

### Módulo de Autenticación
- Registro y login con JWT stateless
- Cifrado BCrypt para contraseñas
- Roles: `ALUMNO`, `TUTOR_CENTRO`, `TUTOR_EMPRESA`, `ADMIN`
- Seguridad por método con `@PreAuthorize` en cada endpoint

### Módulo de Prácticas
- CRUD completo de convenios de prácticas
- Control de estados: `BORRADOR` → `ACTIVA` → `FINALIZADA`
- Separación de tutor de centro y tutor de empresa (dos figuras independientes)
- Paginación con `Page<T>` en listados

### Módulo de Seguimientos (doble validación)
El diseño más importante del sistema. Un parte semanal del alumno pasa por dos validaciones diferenciadas:

```
Alumno registra parte
        │
        ▼
[PENDIENTE_EMPRESA]  ──► Tutor empresa rechaza ──► [RECHAZADO]
        │                                                │
        │ Tutor empresa valida                           │ Incidencia automática
        ▼                                               al tutor del centro
[PENDIENTE_CENTRO]
        │
        │ Tutor centro da visto bueno
        ▼
  [COMPLETADO] ──► Se suman horas al contador FCT
```

Esta separación refleja el proceso real de las FCT: el tutor de empresa valida el trabajo diario (equivale a la firma del parte en papel), y el tutor del centro supervisa el proceso académico.

### Módulo de Incidencias
- Alta de incidencias por el alumno con un botón directo
- Generación automática de incidencias cuando el tutor de empresa rechaza un parte
- Notificación inmediata al tutor del centro sin intervención del alumno

### Gestión de entidades maestras
- Centros educativos y empresas colaboradoras
- Listados para poblar formularios del sistema

---

## Estructura del proyecto

```
Nexus-TFG/
├── backend/
│   └── tfg-nexus-api/
│       ├── src/main/java/com/tfg/api/
│       │   ├── controllers/          # Endpoints REST
│       │   ├── services/             # Lógica de negocio
│       │   │   └── impl/
│       │   ├── models/
│       │   │   ├── entities/         # Entidades JPA
│       │   │   ├── dto/              # Request/Response
│       │   │   └── mappers/          # MapStruct
│       │   ├── repositories/         # Spring Data JPA
│       │   ├── security/             # JWT + filtros
│       │   └── exceptions/           # BusinessRuleException
│       └── src/main/resources/
│           └── db/migration/         # V1, V2, V3... Flyway
├── frontend/
│   └── lib/
│       ├── core/
│       │   └── theme/
│       │       └── app_theme.dart    # Sistema de diseño Nexus
│       └── presentation/
│           ├── providers/            # AuthProvider, PracticaProvider
│           └── screens/              # LoginScreen, DashboardScreen
├── docker-compose.yml
├── .env.example                      # Plantilla de variables de entorno
├── ARQUITECTURA_API.md               # Contrato REST completo
├── DESIGN_SYSTEM.md                  # Sistema de diseño Nexus
└── BBDD-TFG.sql                      # Esquema de referencia (Flyway lo aplica automáticamente)
```

---

## Arranque rápido

### Prerequisitos
- Docker Desktop instalado y corriendo
- Git

### 1. Clonar el repositorio
```bash
git clone https://github.com/ikeracv28/Nexus-TFG.git
cd Nexus-TFG
```

### 2. Configurar variables de entorno
```bash
cp .env.example .env
# Edita .env con tus valores (o deja los de ejemplo para desarrollo local)
```

### 3. Construir e iniciar con Docker
```bash
docker-compose build --no-cache
docker-compose up -d
```

Esto levanta automáticamente:
- PostgreSQL con el esquema creado por Flyway
- La API Spring Boot con los usuarios de prueba
- El frontend Flutter compilado en Nginx

### 4. Abrir la aplicación
```
http://localhost:3000
```

### Usuarios de prueba

| Rol | Email | Contraseña |
|-----|-------|-----------|
| Administrador | admin@nexus.edu | Admin@Nexus2026 |
| Tutor Centro | tutor@nexus.edu | Tutor@Nexus2026 |
| Tutor Empresa | tutorempresa@nexus.edu | Empresa@Nexus2026 |
| Alumno | alumno@nexus.edu | Alumno@Nexus2026 |

---

## API Reference

La API REST corre en `http://localhost:8080/api/v1`

### Autenticación
```http
POST /auth/register    # Registro de usuario
POST /auth/login       # Login → devuelve JWT
GET  /auth/me          # Perfil del usuario autenticado
```

### Prácticas
```http
GET    /practicas              # Listar todas (paginado) — ADMIN, TUTOR_CENTRO, TUTOR_EMPRESA
POST   /practicas              # Crear práctica — ADMIN, TUTOR_CENTRO
GET    /practicas/{id}         # Obtener práctica — autenticado
GET    /practicas/alumno/{id}  # Prácticas de un alumno — autenticado
PUT    /practicas/{id}         # Actualizar — ADMIN, TUTOR_CENTRO
DELETE /practicas/{id}         # Eliminar (solo BORRADOR) — ADMIN
```

### Seguimientos
```http
POST   /seguimientos                    # Crear parte — ALUMNO
GET    /seguimientos/practica/{id}      # Partes de una práctica — autenticado
PATCH  /seguimientos/{id}/validar-empresa  # Validar (1ª fase) — TUTOR_EMPRESA
PATCH  /seguimientos/{id}/validar-centro   # Validar (2ª fase) — TUTOR_CENTRO
```

### Entidades maestras
```http
GET /centros      # Listar centros educativos
GET /empresas     # Listar empresas colaboradoras
```

Todos los endpoints (excepto auth) requieren el header:
```
Authorization: Bearer <token>
```

---

## Tests

El proyecto cuenta con **121 tests** distribuidos en 18 clases, con JUnit 5 + MockMvc + Spring Security Test.

```bash
cd backend/tfg-nexus-api
./mvnw test
```

```
[INFO] Tests run: 121, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

| Área | Clases | Tests |
|------|--------|-------|
| Controladores (Auth, Práctica, Admin, Chat) | 4 | 21 |
| Seguridad OWASP (control de acceso, JWT, rate limit, CORS) | 4 | 30 |
| Servicios (ausencias, incidencias, seguimientos, chat, admin) | 9 | 69 |
| Persistencia de modelos | 1 | 1 |

Casos destacados:
- Doble validación de seguimientos (tutor empresa → tutor centro)
- Control de acceso por rol en cada endpoint (`@PreAuthorize`)
- Rate limiting: bloqueo tras N peticiones en ventana de tiempo
- Cabeceras de seguridad HTTP (CSP, HSTS, X-Frame-Options)
- JWT: expiración, firma inválida, token en lista negra
- Propiedad de prácticas: un alumno no accede a prácticas ajenas
- Flujo completo de ausencias: solicitud, aprobación y rechazo

---

## Sistema de diseño

Nexus usa un sistema de diseño propio definido en `core/theme/app_theme.dart`:

| Token | Color | Uso |
|-------|-------|-----|
| `NexusColors.primary` | `#185FA5` | Acciones principales, activo |
| `NexusColors.success` | `#3B6D11` | Validado, completado |
| `NexusColors.warning` | `#BA7517` | Pendiente, en proceso |
| `NexusColors.danger` | `#E24B4A` | Incidencias, rechazado, error |
| `NexusColors.surface` | `#FFFFFF` | Cards y paneles |
| `NexusColors.surfaceAlt` | `#F5F5F3` | Fondo general |

Estilo visual: Notion/Linear. Sin Material azul genérico, inputs con borde fino, tipografía limpia.

---

## Hoja de ruta

### ✅ Hito 1 — 25% (completado)
- Esquema de BBDD con Flyway (V1-V3)
- Autenticación JWT completa
- Endpoints de entidades maestras
- Arquitectura base del backend

### ✅ Hito 2 — 50% (completado)
- CRUD completo de prácticas con seguridad por roles
- 10 tests de integración
- Sistema de diseño Flutter (`app_theme.dart`)
- Pantallas de login y dashboard conectadas a la API
- Detección y rediseño del flujo de validación de seguimientos
- Docker Compose con los tres servicios

### ✅ Hito 3 — 75% (completado)
- Chat en tiempo real con WebSocket/STOMP
- Gestión de ausencias (solicitud, aprobación, rechazo)
- Panel de administración con auditoría de acciones
- Rate limiting y cabeceras de seguridad OWASP
- Pantallas Flutter: chat, ausencias, administración
- Navegación adaptativa (NavigationRail web / BottomNav móvil)

### 🔄 Hito 4 — 100% (entrega final)
- Pulido de la interfaz y corrección de errores
- Tests de integración adicionales
- Documentación final y memoria del TFG

---

## Repositorio

Este es el repositorio de entrega oficial del TFG, mantenido limpio y sin artefactos de desarrollo.

---

## Autor

**Iker Acevedo Donate**  
Ciclo Formativo de Grado Superior · CampusFP  
Trabajo de Fin de Grado — curso 2025-2026

---

<div align="center">
<sub>Nexus · Sistema de Gestión de Prácticas Académicas · CampusFP 2025</sub>
</div>
