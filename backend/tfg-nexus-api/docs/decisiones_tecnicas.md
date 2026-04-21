# Nexus TFG - Bitácora de Decisiones Técnicas

Este documento detalla la evolución arquitectónica del backend y el razonamiento detrás de cada elección tecnológica.

## 1. Identidad del Proyecto
**Nombre:** Nexus TFG (Nexus-API)
**Concepto:** "Nexus" representa el punto de unión entre alumnos, centros educativos y empresas, centralizando la gestión de la FP Dual y prácticas externas.

## 2. Decisiones de Base (Infraestructura)

### Java 21 LTS + Spring Boot 3.4.1
- **Razón:** Se opta por las versiones más modernas y estables. Java 21 introduce mejoras de rendimiento (Virtual Threads) y sintaxis (Records) que utilizaremos para los DTOs, reduciendo el código repetitivo.
- **Impacto:** Un backend más ligero, rápido y preparado para el futuro.

### Flyway (Migraciones de Base de Datos)
- **Razón:** En lugar de permitir que Hibernate genere las tablas (`ddl-auto=update`), delegamos el control a Flyway.
- **Decisión Crítica:** El esquema inicial (`V1`) ya incluye la separación de `tutor_centro_id` y `tutor_empresa_id` en la tabla `practicas`. Esta decisión previene problemas futuros donde un solo tutor no bastaba para cubrir ambas responsabilidades (académica y profesional).

### Arquitectura de Paquetes
- **Razón:** Se implementa una separación clara de responsabilidades:
    - `controllers`: Exposición de la API.
    - `services`: Lógica de negocio pura.
    - `models.entity`: Espejo de la base de datos (JPA).
    - `models.dto`: Objetos ligeros para transferencia de datos.
    - `models.mapper`: Automatización de la conversión entre Entidad y DTO (vía MapStruct).

## 3. Seguridad y Comunicación

### JWT (Stateless)
- **Razón:** Al ser una API que servirá a una aplicación móvil (Flutter), no podemos usar sesiones tradicionales de servidor (JSESSIONID). JWT permite que el cliente sea el encargado de enviar su identidad en cada petición.

### MapStruct
- **Razón:** Evitar el mapeo manual de objetos. MapStruct genera código en tiempo de compilación, lo que es mucho más rápido que usar librerías de reflexión como ModelMapper.

## 4. Capa de Persistencia (Repositories)

### Spring Data JPA & Query Derivation
- **Razón:** Utilizamos `JpaRepository` para delegar el CRUD a Spring. 
- **Decisión Crítica:** El uso de **Query Derivation** (como `findByEmail`) simplifica el código al no requerir sentencias SQL manuales. Spring analiza el nombre del método y genera la consulta óptima para PostgreSQL.

### Modelo de Dominio Core (Entities & Relationships)
- **Empresa:** Se diseña como una entidad independiente que almacena datos corporativos (CIF, contacto) necesarios para el convenio de prácticas.
- **Practica (Entidad Pivote):** Es el núcleo funcional del sistema. Relaciona a un `Alumno` con su `Empresa`, un `TutorCentro` y un `TutorEmpresa`. 
    - **Decisión Crítica:** Se opta por relaciones `@ManyToOne` con `FetchType.LAZY` en todas las claves foráneas para evitar la carga masiva de datos innecesarios en memoria (N+1 Select Problem).
- **Seguimiento (Diario de Actividad):** Permite el registro cronológico de tareas. 
    - **Decisión Crítica:** Se incluye una relación con el `Usuario` (Tutor) que valida el registro, permitiendo un flujo de aprobación formal integrado en la base de datos.

### Repositorios Especializados
- **PracticaRepository:** Se incluyen métodos personalizados para filtrar por alumno, tutor de centro y estado, permitiendo que cada rol visualice únicamente los convenios que le corresponden.
- **SeguimientoRepository:** Implementa ordenación cronológica descendente por defecto (`OrderByFechaRegistroDesc`) para que el alumno y el tutor vean siempre la actividad más reciente primero.

### Uso de Optional
- **Razón:** Todos los métodos de búsqueda devuelven un objeto de tipo `Optional<T>`. 
- **Impacto:** Esto obliga al desarrollador (a nosotros) a manejar explícitamente el caso de "dato no encontrado", evitando el clásico y temido `NullPointerException` en producción.

## 5. Lógica de Autenticación y Seguridad

### Cifrado BCrypt (SecurityConfig)
- **Razón:** No se almacenan contraseñas en texto plano. Se utiliza `BCryptPasswordEncoder` para generar hashes seguros con 'salt' automático.
- **Seguridad:** Cumple con los estándares de la OWASP para la protección de credenciales.

### Java 21 Records (DTOs)
- **Razón:** Se utilizan `Records` para los objetos de transferencia de datos (como `RegisterRequest`). 
- **Decisión Crítica:** Al ser inmutables, garantizan que los datos que llegan del frontend no se modifiquen durante el flujo del servicio, lo que hace el sistema más predecible y seguro.

### Capa de Servicio (AuthService)
- **Razón:** Se separa la lógica de negocio (validar duplicados, cifrar contraseñas, asignar roles) de la capa de transporte (Controladores).
- **Transaccionalidad:** Se usa `@Transactional` para asegurar la integridad de los datos en el proceso de registro (todo o nada).

### Capa de Control (AuthController)
- **Razón:** Se exponen endpoints REST bajo la ruta `/api/v1/auth`. 
- **Validación:** Se utiliza `@Valid` para interceptar datos incorrectos antes de que lleguen al servicio, ahorrando recursos de procesamiento.
- **CORS:** Se habilita `@CrossOrigin(origins = "*")` para permitir que el cliente Flutter (ya sea en web o móvil) pueda consumir la API sin bloqueos de navegador.
- **Naming:** Se sigue la convención de plurales para recursos, aunque en autenticación se usan verbos de acción (`/login`, `/register`) por ser operaciones procedimentales.

### Gestión Global de Errores (GlobalExceptionHandler)
- **Razón:** Se implementa un interceptor centralizado mediante `@RestControllerAdvice` para estandarizar las respuestas ante fallos.
- **ErrorResponse (Record):** Se define un esquema único de error en formato JSON para que el cliente Flutter pueda procesar las excepciones de forma predecible.
- **Tratamiento de Validación:** Los errores de Bean Validation (`@NotBlank`, `@Email`) se desglosan en un mapa de campos, permitiendo al frontend marcar exactamente qué input del formulario es inválido.
- **Estrategia de Status Code:**
    - **404:** Para recursos no encontrados (`ResourceNotFoundException`).
    - **401:** Para fallos de credenciales (`BadCredentialsException`).
    - **409 (Conflict):** Se elige para errores de lógica de negocio (ej: email duplicado) en lugar del genérico 500, indicando que el problema es una violación de reglas de dominio, no un fallo del servidor.

### 6. Arquitectura de Seguridad JWT (Task 3)


### JwtUtils (Generación y Validación)
- **Razón:** Centraliza la lógica de creación de tokens. Utiliza el algoritmo HS256 y una clave secreta configurable.
- **Seguridad:** Los tokens incluyen fecha de emisión y expiración (24h por defecto) para mitigar riesgos de robo de tokens.

### UserDetailsServiceImpl (Puente de Datos)
- **Razón:** Implementa la interfaz estándar de Spring Security para cargar usuarios desde nuestra base de datos PostgreSQL.
- **Conversión:** Transforma nuestras entidades `Rol` en `GrantedAuthority`, permitiendo que el framework gestione los permisos de forma nativa.

### JwtAuthenticationFilter (Interceptor de Peticiones)
- **Razón:** Implementa un filtro `OncePerRequestFilter` que extrae el token de la cabecera `Authorization: Bearer`.
- **Estrategia:** Valida la firma del token y establece el contexto de seguridad en cada petición, permitiendo que la API sea **Stateless**.

### Seguridad JWT y Tests de Integración
- **Razón:** Se ha corregido la inyección de dependencias en los filtros de seguridad y se ha validado que el servidor emite tokens JWT válidos tras el registro y login.
- **Verificación:** Superados tests de integración web (`AuthControllerTest`) y persistencia (`ModelPersistenceTest`).

## 8. Sincronización y Fortalecimiento (Hito 1 - 25%)

### Sincronización de Contrato de APIs
- **Razón:** Existía una discrepancia entre la documentación teórica (`ARQUITECTURA_API.md`) y el código implementado.
- **Acción:** Se han implementado los endpoints mínimos de "Maestros" (Centros y Empresas) y el perfil de usuario autenticado (`/me`) para cumplir con las promesas de la memoria de seguimiento.
- **Roadmap:** Se han marcado explícitamente los módulos de Prácticas, Seguimientos e Incidencias como "Diseño de Contrato" para el Hito 2.

### Módulo de Perfil de Usuario (/me)
- **Razón:** Permitir al cliente Flutter recuperar el perfil completo del usuario (nombre, email, roles, centro) a partir del token JWT.
- **Implementación:** Se extrae el `username` (email) del `SecurityContextHolder` en el `UsuarioService`.

### Mapeo de Relaciones en DTOs
- **Razón:** El DTO `UsuarioResponse` debe incluir información de entidades relacionadas sin causar ciclos.
- **Decisión:** Se utiliza MapStruct para extraer el `nombre` del `Centro` asociado y aplanarlo en el JSON final.

---
*Última actualización: 6 de abril de 2026*
### Módulo de Gestión de Prácticas (Core Business)
- **Implementación de PracticaService:** Lógica para la creación de convenios vinculando Alumno, Empresa y Tutores.
- **DTOs de Negocio:** Diseño de records para la transferencia de datos de prácticas, evitando ciclos de referencia circular en el JSON.
- **Seguridad por Método:** Introducción de `@PreAuthorize` para asegurar que solo los perfiles administrativos puedan gestionar los expedientes de prácticas.

---
*Última actualización: 6 de abril de 2026*
