<div align="center">

# NEXUS
### Sistema de Gestión de Prácticas Académicas FCT

**Trabajo de Fin de Grado · Iker Acevedo Donate · CampusFP**

---

[![Java](https://img.shields.io/badge/Java-21-orange?style=flat-square&logo=openjdk)](https://openjdk.org/projects/jdk/21/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.4.1-brightgreen?style=flat-square&logo=springboot)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-316192?style=flat-square&logo=postgresql)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker)](https://www.docker.com/)

</div>

---

## ¿Qué es Nexus?

Nexus es una plataforma web que digitaliza y centraliza la gestión de las prácticas en empresa (FCT) de los ciclos formativos de FP. Elimina el caos de correos, excels y llamadas entre alumnos, tutores de centro y tutores de empresa, reuniendo a todos los actores en un único entorno digital con seguimiento en tiempo real.

El sistema implementa cuatro roles diferenciados (`ALUMNO`, `TUTOR_CENTRO`, `TUTOR_EMPRESA`, `ADMIN`), seguimiento diario con validación en dos fases, gestión de incidencias automática, chat interno por práctica y panel de administración completo.

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Backend | Java 21 + Spring Boot 3.4.1 |
| Seguridad | Spring Security + JWT (jjwt 0.12.5) + BCrypt |
| Persistencia | PostgreSQL 15 + Hibernate (JPA) + Flyway |
| Mapeo | MapStruct 1.6.3 + Lombok |
| Frontend | Flutter (Dart) SDK ^3.11.4 + Provider + Dio + go_router |
| Infraestructura | Docker Compose (db + backend + frontend/Nginx) |

---

## Requisitos previos

- Docker Desktop instalado y arrancado
- Git

---

## Arranque rápido

```bash
git clone https://github.com/ikeracv28/TFG-Seguimiento.git
cd TFG-Seguimiento
cp .env.example .env
docker-compose up -d
```

La primera vez tarda ~3-5 minutos (descarga imágenes, compila el backend con Maven y aplica las migraciones Flyway automáticamente).

| Servicio | URL |
|----------|-----|
| Aplicación web (Flutter) | http://localhost:3000 |
| API REST | http://localhost:8080 |

---

## Usuarios de prueba

Ver **[USUARIOS_PRUEBA.md](USUARIOS_PRUEBA.md)** para credenciales y escenarios de demostración completos.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                     NEXUS PLATFORM                       │
│                                                          │
│  ┌──────────────┐    REST/JWT    ┌──────────────────┐   │
│  │   Flutter    │ ─────────────► │   Spring Boot    │   │
│  │  (Web)       │                │   API REST       │   │
│  │  Puerto 3000 │ ◄───────────── │   Puerto 8080    │   │
│  └──────────────┘    WebSocket   └────────┬─────────┘   │
│                                           │ JPA/Flyway  │
│                                  ┌────────▼─────────┐   │
│                                  │   PostgreSQL 15   │   │
│                                  │   Puerto 5432     │   │
│                                  └──────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Estructura del proyecto

```
TFG-Seguimiento/
├── backend/
│   └── tfg-nexus-api/
│       ├── src/main/java/com/tfg/api/
│       │   ├── controllers/        # Endpoints REST (@PreAuthorize)
│       │   ├── services/impl/      # Lógica de negocio
│       │   ├── models/dto/         # Request/Response DTOs
│       │   ├── models/entity/      # Entidades JPA
│       │   ├── models/mapper/      # MapStruct
│       │   ├── security/           # JWT filter + WebSocket auth
│       │   └── exceptions/         # GlobalExceptionHandler
│       └── src/main/resources/
│           └── db/migration/       # V1–V20 Flyway migrations
├── frontend/
│   └── lib/
│       ├── core/theme/             # NexusColors, sistema de diseño
│       ├── data/services/          # API clients (Dio)
│       └── presentation/
│           ├── providers/          # AuthProvider, state management
│           └── screens/            # Pantallas por rol
├── docker-compose.yml
├── ARQUITECTURA_API.md
├── PLAN_SEGURIDAD_OWASP.md
├── DECISIONES_TECNICAS.md
├── ERD_DATABASE.md
├── UML_CLASS_DIAGRAM.md
├── MANUAL_USUARIO.md
└── USUARIOS_PRUEBA.md
```

---

## Módulos del sistema

### Autenticación y autorización
- Login con JWT stateless; BCrypt para contraseñas
- `@PreAuthorize` explícito en cada endpoint
- Autenticación WebSocket con interceptor JWT

### Prácticas FCT
- CRUD completo con ciclo de vida: `BORRADOR → ACTIVA → FINALIZADA`
- Dos figuras de tutor independientes (centro y empresa)

### Seguimientos con doble validación

```
Alumno registra parte
        │
        ▼
[PENDIENTE_EMPRESA] ──► Tutor empresa rechaza ──► [RECHAZADO]
        │                                               │
        │ Tutor empresa valida                          │ Incidencia automática
        ▼                                              al tutor del centro
[PENDIENTE_CENTRO]
        │
        │ Tutor centro da visto bueno
        ▼
  [COMPLETADO] ──► Se suman horas al contador FCT
```

### Chat en tiempo real
- WebSocket/STOMP con canales por práctica (ALUMNO / TUTOR)
- Soporte de mensajes de texto y adjuntos binarios

### Gestión de ausencias e incidencias
- Registro de ausencias con justificante
- Incidencias manuales y automáticas (generadas por rechazo de parte)

### Panel de administración
- Gestión de centros, empresas y usuarios
- Estadísticas del sistema

---

## Tests

| Área | Clases de test | Tests |
|------|---------------|-------|
| Seguridad OWASP | 6 | ~60 |
| Controllers | 10 | ~130 |
| Servicios | 2 | ~30 |
| **Total** | **~18** | **~258** |

```bash
cd backend/tfg-nexus-api
./mvnw test
```

Cobertura JaCoCo generada en `target/site/jacoco/`.

---

## Documentación técnica

| Documento | Contenido |
|-----------|-----------|
| [ARQUITECTURA_API.md](ARQUITECTURA_API.md) | Contrato REST completo — todos los endpoints |
| [PLAN_SEGURIDAD_OWASP.md](PLAN_SEGURIDAD_OWASP.md) | Plan de seguridad con trazabilidad OWASP Top 10 |
| [DECISIONES_TECNICAS.md](DECISIONES_TECNICAS.md) | Decisiones de arquitectura justificadas |
| [ERD_DATABASE.md](ERD_DATABASE.md) | Diagrama entidad-relación |
| [UML_CLASS_DIAGRAM.md](UML_CLASS_DIAGRAM.md) | Diagramas de clases |
| [MANUAL_USUARIO.md](MANUAL_USUARIO.md) | Manual de uso por rol con capturas |
| [USUARIOS_PRUEBA.md](USUARIOS_PRUEBA.md) | Credenciales demo y escenarios de prueba |

---

## Autor

**Iker Acevedo Donate**  
Ciclo Formativo de Grado Superior · CampusFP  
Trabajo de Fin de Grado — curso 2025-2026

---

<div align="center">
<sub>Nexus · Sistema de Gestión de Prácticas Académicas · CampusFP 2026</sub>
</div>
