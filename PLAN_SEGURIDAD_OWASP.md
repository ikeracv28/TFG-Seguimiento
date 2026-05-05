# PLAN DE SEGURIDAD OWASP — Nexus TFG

> **Skill de referencia**: https://skills.sh/hoodini/ai-agents-skills/owasp-security
> Ejecutar `/owasp-security` sobre cada archivo modificado antes de cerrar cualquier tarea.
> Este plan usa `- [ ]` para que una IA pueda hacer check y seguir la guia de forma autonoma.

---

## Convenciones de severidad

- **[CRITICO]** — Vulnerabilidad explotable directamente. Bloquea entrega.
- **[ALTO]** — Riesgo real pero requiere condiciones adicionales.
- **[MEDIO]** — Mejora defensiva importante, no bloquea entrega.

---

## BLOQUE 1 — Vulnerabilidades en código existente (OWASP Top 10)

Orden de implementacion obligatorio: resolver primero los CRITICOS antes de pasar al siguiente bloque.

---

### A01 — Broken Access Control

#### 1.1 CORS abierto a wildcard [CRITICO]

**Archivos afectados:**
- `backend/tfg-nexus-api/src/main/java/com/tfg/api/config/SecurityConfig.java` linea 85
- `backend/tfg-nexus-api/src/main/java/com/tfg/api/controllers/AuthController.java` linea 20
- `backend/tfg-nexus-api/src/main/java/com/tfg/api/controllers/PracticaController.java` linea 25
- Todos los demas controllers con `@CrossOrigin(origins = "*")`

**Por que es un problema:** CORS abierto permite que cualquier pagina web externa llame a la API con credenciales del usuario. Combinado con JWT en header Authorization puede facilitar ataques de tipo CSRF avanzado.

- [x] En `SecurityConfig.java`: reemplazar `List.of("*")` por lista de origenes permitidos reales:
  ```java
  configuration.setAllowedOrigins(List.of(
      "http://localhost:3000",
      "http://localhost:8080",
      "${ALLOWED_ORIGIN:http://localhost:3000}"
  ));
  configuration.setAllowCredentials(true);
  ```
- [x] Añadir la variable `ALLOWED_ORIGIN` al `.env` con el dominio de produccion.
- [x] Eliminar la anotacion `@CrossOrigin(origins = "*")` de `AuthController.java`.
- [x] Eliminar la anotacion `@CrossOrigin(origins = "*")` de `PracticaController.java`.
- [x] Buscar con grep todos los controllers que tengan `@CrossOrigin` y eliminarlos (la config global de SecurityConfig es suficiente):
  - `SeguimientoController.java`
  - `IncidenciaController.java`
  - `UsuarioController.java` (no tenía)
  - `CentroController.java` (no tenía)
  - `EmpresaController.java` (no tenía)

#### 1.2 Verificacion de propiedad en acceso por ID de alumno [CRITICO]

**Archivo:** `PracticaController.java` linea 85

**Por que es un problema:** La expresion SpEL `#alumnoId == authentication.principal.id` falla silenciosamente porque `authentication.principal` es un objeto `UserDetails` que no tiene campo `.id` accesible directamente. El check se evalua como false para todos los alumnos, lo que significa que ningun alumno puede ver sus propias practicas por este endpoint. Pero si la evaluacion fallara de otra manera, cualquier alumno podria ver practicas de otros.

- [x] En `PracticaController.java` linea 85: corregir la expresion SpEL usando el email como identificador:
  ```java
  @PreAuthorize("hasAnyRole('ADMIN','TUTOR_CENTRO','TUTOR_EMPRESA') or @practicaService.perteneceAlAlumnoAutenticado(#alumnoId, authentication.name)")
  ```
- [x] En `PracticaServiceImpl.java`: implementar el metodo `perteneceAlAlumnoAutenticado(Long alumnoId, String email)` que comprueba si el alumno con ese ID tiene el email del usuario autenticado.
- [x] Anadir test de integracion: alumno A no puede ver practicas de alumno B por este endpoint. (A01AccessControlTest — 8/8 pasan, 01/05/2026)

#### 1.3 Endpoint GET /practicas/{id} sin restriccion de propiedad [ALTO]

**Archivo:** `PracticaController.java` linea 74-77

**Por que es un problema:** Cualquier usuario autenticado (incluyendo alumnos de otras practicas) puede ver los detalles de cualquier practica conociendo su ID. Solo deberia verse la practica propia o las asignadas al tutor.

- [x] Cambiar `@PreAuthorize("isAuthenticated()")` por:
  ```java
  @PreAuthorize("hasAnyRole('ADMIN','TUTOR_CENTRO','TUTOR_EMPRESA') or @practicaService.esParticipante(#id, authentication.name)")
  ```
- [x] Implementar `esParticipante(Long practicaId, String email)` en `PracticaServiceImpl`: devuelve true si el usuario es el alumno, tutor centro o tutor empresa de esa practica.
- [x] Test: alumno sin practica asignada no puede ver practica ajena. (A01AccessControlTest — 8/8 pasan, 01/05/2026)
- [x] Fix: @Service("practicaService") en PracticaServiceImpl — el bean estaba registrado como "practicaServiceImpl" y el SpEL no encontraba "practicaService". Causaba 500 en cualquier acceso de alumno por ID. (01/05/2026)

---

### A02 — Cryptographic Failures

#### 2.1 JWT Secret con entropia insuficiente y uso incorrecto de getBytes() [CRITICO]

**Archivo:** `JwtUtils.java` linea 94

**Por que es un problema:** `secret.getBytes()` usa la codificacion de la JVM (UTF-8), pero si el secret tiene menos de 32 bytes el algoritmo HMAC-SHA256 lo rellenara o fallara. Ademas, el secret actual `NexusTFG2026_SecretKey_Complex_Security_9876543210` esta en texto plano y puede estar en el historial de git.

- [x] En `JwtUtils.java`: cambiar `getSigningKey()` para decodificar el secret desde Base64:
  ```java
  private SecretKey getSigningKey() {
      byte[] keyBytes = Decoders.BASE64.decode(secret);
      return Keys.hmacShaKeyFor(keyBytes);
  }
  ```
- [ ] Generar un nuevo secret aleatorio de 64 bytes en Base64:
  ```bash
  openssl rand -base64 64
  ```
- [ ] Actualizar el `.env` con el nuevo secret. Nunca commitear el `.env` con valores reales.
- [ ] Verificar que `.gitignore` incluye `.env` (si no, anadirlo inmediatamente).
- [ ] Anadir al `README.md` del backend: instrucciones para generar el secret en el primer deploy.

#### 2.2 HTTPS no configurado en el cliente Flutter [ALTO]

**Archivo:** `frontend/lib/core/config/api_client.dart` linea 9

**Por que es un problema:** La URL hardcodeada `http://localhost:8080/api/v1` usa HTTP sin cifrado. En produccion el token JWT viajaria en texto plano por la red.

- [ ] En `api_client.dart`: usar variable de entorno para la URL base en lugar de literal:
  ```dart
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
  ```
- [ ] En la configuracion de Nginx del frontend: forzar redirect HTTP → HTTPS en produccion.
- [ ] Documentar en `docker-compose.yml` o README como configurar SSL en produccion.

#### 2.3 Politica de contrasena debil [ALTO]

**Archivo:** `RegisterRequest.java` linea 35

**Por que es un problema:** El minimo de 8 caracteres sin restricciones de complejidad permite contrasenas triviales como `12345678`.

- [x] En `RegisterRequest.java`: anadir validacion de complejidad con un patron regex (mayuscula + minuscula + numero + especial, min 10 chars). (01/05/2026)
  ```java
  @Pattern(
      regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^a-zA-Z0-9]).{10,}$",
      message = "La contrasena debe tener al menos una mayuscula, una minuscula, un numero y un caracter especial"
  )
  String password
  ```
- [x] Migracion Flyway V6 actualiza hashes BCrypt de 4 usuarios de prueba a politica 12+ chars (Admin@Nexus2026, Tutor@Nexus2026, Alumno@Nexus2026, Empresa@Nexus2026). (28/04/2026)
- [x] `CLAUDE.md` — tabla usuarios de prueba — actualizada con las nuevas contrasenas. (28/04/2026)

---

### A03 — Injection

#### 3.1 Parametro nuevoEstado sin validacion de valores [ALTO]

**Archivo:** `PracticaController.java` linea 127

**Por que es un problema:** `@RequestParam String nuevoEstado` acepta cualquier cadena. Si el servicio no valida estrictamente, podria insertarse un estado arbitrario en la BD.

- [x] Validar `nuevoEstado` contra `Set.of("BORRADOR","ACTIVA","FINALIZADA")` en `PracticaServiceImpl.cambiarEstado()`. Lanza `BusinessRuleException` con valores permitidos si el String no esta en el conjunto. (Implementado 28/04/2026 — sin enum para evitar migración de esquema)
- [ ] Hacer lo mismo con `nuevoEstado` en `SeguimientoController` (PENDIENTE_EMPRESA, PENDIENTE_CENTRO, RECHAZADO, COMPLETADO) — crear enum `EstadoSeguimiento`.

---

### A04 — Insecure Design

#### 4.1 Sin rate limiting en endpoints de autenticacion [CRITICO]

**Archivos afectados:** `AuthController.java`, `SecurityConfig.java`

**Por que es un problema:** Sin rate limiting, un atacante puede intentar millones de combinaciones de contrasena contra `/auth/login` sin ninguna proteccion.

- [x] Crear `RateLimitFilter.java` en `security/` (implementacion propia sin dependencias externas, ventana deslizante con ConcurrentHashMap — @Component @Order(1) se registra automaticamente antes de Spring Security).
- [x] Registrar el filtro: @Order(1) garantiza ejecucion antes del JwtAuthenticationFilter.
- [ ] Test: verificar que el endpoint devuelve 429 tras 10 intentos en 1 minuto desde la misma IP.

#### 4.2 Sin limite en la creacion de seguimientos por alumno [MEDIO]

**Archivo:** `SeguimientoServiceImpl.java`

- [x] En el metodo que crea un seguimiento: verificar que el alumno no tiene mas de 1 seguimiento en estado `PENDIENTE_EMPRESA` para la misma semana ISO (lunes-domingo). (01/05/2026)
- [x] Lanzar `BusinessRuleException` si ya existe uno pendiente para esa semana. (01/05/2026)

---

### A05 — Security Misconfiguration

#### 5.1 Logs de SQL y debug en application.properties base [ALTO]

**Archivo:** `backend/tfg-nexus-api/src/main/resources/application.properties` lineas 13-14, 23-24

**Por que es un problema:** `spring.jpa.show-sql=true` y `logging.level.com.tfg.api=DEBUG` en el properties base hacen que en produccion se expongan consultas SQL y trazas internas si no se activa explicitamente el perfil prod.

- [ ] En `application.properties`: cambiar los valores base a valores seguros:
  ```properties
  spring.jpa.show-sql=false
  spring.jpa.properties.hibernate.format_sql=false
  logging.level.com.tfg.api=WARN
  logging.level.org.springframework.security=WARN
  ```
- [ ] Verificar que `application-dev.properties` tiene los overrides para debug local.
- [ ] Verificar que `application-prod.properties` mantiene `WARN`.

#### 5.2 Cabeceras de seguridad HTTP ausentes [ALTO]

**Archivo:** `SecurityConfig.java`

**Por que es un problema:** Sin cabeceras como `X-Content-Type-Options`, `X-Frame-Options` o `Content-Security-Policy`, el navegador es vulnerable a clickjacking, MIME sniffing y XSS.

- [x] En `SecurityConfig.java`, dentro del metodo `securityFilterChain`, anadir configuracion de headers:
  ```java
  http.headers(headers -> headers
      .frameOptions(frame -> frame.deny())
      .contentTypeOptions(Customizer.withDefaults())
      .httpStrictTransportSecurity(hsts -> hsts
          .includeSubDomains(true)
          .maxAgeInSeconds(31536000))
      .xssProtection(Customizer.withDefaults())
  );
  ```
- [x] En el `nginx.conf` del frontend: anadir headers de seguridad para respuestas estaticas (X-Frame-Options DENY, X-Content-Type-Options nosniff, Referrer-Policy, X-XSS-Protection, CSP). (01/05/2026)

---

### A07 — Identification and Authentication Failures

#### 7.1 Account enumeration por mensajes de error distintos [ALTO]

**Archivo:** `AuthServiceImpl.java` lineas 96-99

**Por que es un problema:** Los mensajes "El correo electronico ya se encuentra registrado" y "El DNI introducido ya existe" permiten a un atacante determinar si un email o DNI ya estan en el sistema. Esto es account enumeration, catalogado como CWE-204.

- [x] En `validarUnicidad()`: usar un mensaje generico que no revele cual campo falla:
  ```java
  if (usuarioRepository.existsByEmail(request.email()) || usuarioRepository.existsByDni(request.dni())) {
      throw new BusinessRuleException("Los datos introducidos no estan disponibles. Comprueba el formulario.");
  }
  ```
- [x] En `AuthServiceImpl.login()` linea 85: el mensaje "Usuario no encontrado con el email: " expone el email. La excepcion la captura `BadCredentialsException` → ya devuelve "Credenciales de acceso invalidas". Cambiar `ResourceNotFoundException` por `BadCredentialsException` aqui:
  ```java
  Usuario usuario = usuarioRepository.findByEmail(request.email())
      .orElseThrow(() -> new BadCredentialsException("Credenciales de acceso invalidas"));
  ```

#### 7.2 Logout inefectivo — token JWT no se invalida en el servidor [ALTO]

**Por que es un problema:** Al hacer logout, el cliente borra el token localmente pero el token sigue siendo valido en el servidor hasta su expiracion (24h). Un atacante que obtenga el token puede seguir usandolo.

- [x] Cada token JWT incluye claim `jti` (UUID) generado en `JwtUtils.generateToken()`. (28/04/2026)
- [x] `TokenBlacklistService` con `ConcurrentHashMap<String,Boolean>` en memoria — metodos `revocar(jti)` e `estaRevocado(jti)`. (Alternativa sin BD — limitacion conocida: no persiste entre reinicios; aceptable para TFG, en produccion usar Redis con TTL). (28/04/2026)
- [x] `JwtAuthenticationFilter`: verifica `tokenBlacklistService.estaRevocado(jti)` antes de autenticar. (28/04/2026)
- [x] Endpoint `POST /api/v1/auth/logout` con `@PreAuthorize("isAuthenticated()")` en `AuthController`. (28/04/2026)
- [x] `AuthService.logout()` en Flutter llama al endpoint antes de limpiar el storage local. `finally` garantiza limpieza local si el backend falla. (28/04/2026)
- [ ] (Opcional post-TFG) Migrar blacklist a Redis con TTL igual a la expiracion del token para persistencia entre reinicios.

---

### A09 — Security Logging and Monitoring Failures

#### 9.1 Sin logs de eventos de seguridad [ALTO]

**Por que es un problema:** Sin logs de intentos de login fallidos, accesos denegados o cambios de estado criticos, es imposible detectar ataques o hacer forensia despues de un incidente.

- [x] En `GlobalExceptionHandler.java`: anadir log estructurado en el handler de `BadCredentialsException` (ip + user_agent).
- [x] En `GlobalExceptionHandler.java`: loguear `AccessDeniedException` con el usuario autenticado.
- [x] En `SeguimientoServiceImpl.java`: loguear las validaciones de seguimientos a nivel INFO:
  ```java
  log.info("SEGUIMIENTO_VALIDADO_EMPRESA id={} por_tutor={}", seguimiento.getId(), tutorEmail);
  log.info("SEGUIMIENTO_RECHAZADO id={} por_tutor={} motivo={}", seguimiento.getId(), tutorEmail, motivo);
  ```
- [x] En `AuthServiceImpl.registrar()`: loguear nuevo registro a nivel INFO (sin datos sensibles).

---

## BLOQUE 2 — Features pendientes con seguridad OWASP integrada desde el inicio

Cada tarea pendiente del Hito 3 debe implementarse siguiendo estas reglas adicionales.
Ejecutar `/owasp-security` sobre cada archivo antes de cerrar la tarea.

---

### Feature: WebSocket/STOMP — Chat en tiempo real

**Archivos a crear:** `WebSocketConfig.java`, `ChatController.java`, `MensajeService.java`

- [ ] Crear `WebSocketConfig.java` con autenticacion JWT en el handshake:
  ```java
  @Override
  public void configureClientInboundChannel(ChannelRegistration registration) {
      registration.interceptors(new ChannelInterceptor() {
          @Override
          public Message<?> preSend(Message<?> message, MessageChannel channel) {
              StompHeaderAccessor accessor = StompHeaderAccessor.wrap(message);
              if (StompCommand.CONNECT.equals(accessor.getCommand())) {
                  String token = accessor.getFirstNativeHeader("Authorization");
                  // Validar token JWT aqui antes de permitir la conexion
              }
              return message;
          }
      });
  }
  ```
- [ ] El endpoint STOMP debe requerir autenticacion. Ningun mensaje se procesa sin usuario autenticado.
- [ ] Validar en `ChatController` que el usuario solo puede enviar mensajes a canales de practicas en las que participa (alumno, tutor centro o tutor empresa de esa practica).
- [ ] Limitar el tamano maximo del mensaje: `@Size(max=1000)` en el DTO de mensaje.
- [ ] Sanitizar el contenido del mensaje en el servicio (escapar HTML) para prevenir XSS en el frontend.
- [ ] Guardar todos los mensajes en BD con el ID del remitente y timestamp. Nunca confiar en timestamps del cliente.
- [ ] El historial de mensajes solo es accesible para los participantes de la practica (mismo check de propiedad que el chat en tiempo real).
- [ ] Anadir `V7__Chat_Mensajes.sql` con la migracion de la tabla `mensaje` si no existe ya.
- [ ] Test: usuario ajeno a la practica no puede suscribirse al canal de mensajes de esa practica.

---

### Feature: Formulario de registro de seguimiento (Flutter — FAB -> POST /seguimientos)

**Archivos a crear:** `nuevo_seguimiento_screen.dart`, campos en `seguimiento_service.dart`

- [ ] El formulario debe tener validacion cliente: fecha no puede ser futura, horas deben ser entre 1 y 10 por dia, descripcion minimo 20 caracteres.
- [ ] Usar `TextInputFormatter` para limitar la longitud de campos de texto en el formulario.
- [ ] El `SeguimientoService` en Dart debe validar respuesta del servidor: si recibe 429 (rate limit), mostrar mensaje claro al usuario.
- [ ] No enviar el ID del alumno en el body del request — el backend lo extrae del JWT en el servicio. El DTO no debe aceptar `alumnoId` como campo de entrada del usuario.
- [ ] Si el servidor devuelve 409 (parte ya existente para esa semana), mostrar error especifico, no generico.
- [ ] Anadir `@NotNull @FutureOrPresent` al campo `fecha` en `SeguimientoRequest.java` del backend.
- [ ] Anadir `@Min(1) @Max(10)` al campo `horas` en `SeguimientoRequest.java` del backend.
- [ ] Test backend: alumno no puede crear seguimiento con fecha futura.
- [ ] Test backend: alumno no puede crear seguimiento sin practica activa asignada.

---

### Feature: Pantalla de incidencias mejorada (Flutter)

**Archivos afectados:** `incidencias_screen.dart`, `IncidenciaController.java`

- [ ] Verificar que `GET /api/v1/incidencias/practica/{id}` valida que el usuario autenticado es participante de esa practica antes de devolver datos.
- [ ] En Flutter: no mostrar el ID interno de la BD en la UI. Usar el numero de incidencia relativo a la practica.
- [ ] En `IncidenciaRequest.java`: limitar descripcion con `@Size(min=10, max=1000)`.
- [ ] El campo `tipo` de incidencia debe ser un enum, no un String libre. Crear enum `TipoIncidencia` en backend.
- [ ] Al cambiar estado de incidencia, el backend debe verificar que el usuario tiene el rol correcto Y que la incidencia pertenece a una practica donde ese tutor esta asignado.
- [ ] Test: tutor de empresa no puede cambiar estado de incidencias (solo TUTOR_CENTRO puede).

---

### Feature: Verificacion de endpoints tutores en Flutter

**Archivos afectados:** `PanelTutorCentroScreen`, `PanelTutorEmpresaScreen`, servicios Dart correspondientes

- [ ] Verificar que `GET /api/v1/practicas/tutor-empresa/me` y `GET /api/v1/practicas/tutor-centro/me` filtran correctamente por el usuario autenticado (no aceptan parametro de ID).
- [ ] En los providers de Flutter: manejar respuesta 403 mostrando pantalla de error clara, no pantalla vacia.
- [ ] En los providers de Flutter: manejar respuesta 401 (token expirado) redirigiendo al login y limpiando el storage.
- [ ] Anadir timeout de 30 segundos en las llamadas a WebSocket ademas de las llamadas REST.
- [ ] Test Flutter (widget test): verificar que la pantalla del tutor empresa no muestra datos de otro tutor.

---

## BLOQUE 3 — Hardening general (aplicar en paralelo con Bloque 1)

---

### Actualizacion de .gitignore

- [ ] Verificar que `.gitignore` en la raiz del proyecto incluye:
  ```
  .env
  *.env
  .env.local
  backend/tfg-nexus-api/target/
  **/__pycache__/
  ```
- [ ] Si `.env` ya fue commiteado, rotar TODOS los secrets inmediatamente (JWT_SECRET, DB_PASSWORD).
- [ ] Ejecutar `git rm --cached .env` si el archivo esta tracked actualmente.

### Configuracion de base de datos segura

- [ ] En `.env`: cambiar `DB_PASSWORD=password123` por una contrasena generada aleatoriamente de al menos 20 caracteres.
- [ ] En `application.properties`: anadir configuracion de SSL para PostgreSQL en produccion:
  ```properties
  spring.datasource.url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE:disable}
  ```
- [ ] En `application-prod.properties`: `DB_SSL_MODE=require`.

### Dependencias y actualizacion de versiones

- [x] Plugin `dependency-check-maven:10.0.3` configurado en `pom.xml`: `failBuildOnCVSS=7`, reportes HTML+JSON en `target/dependency-check/`. Ejecutar con `./mvnw dependency-check:check`. (28/04/2026)
- [ ] Ejecutar `./mvnw versions:display-dependency-updates` y revisar actualizaciones de seguridad.
- [ ] Ejecutar `flutter pub outdated` en el frontend y actualizar dependencias con vulnerabilidades conocidas.

### Validacion de tamano de payload [MEDIO]

- [x] En `application.properties`: limitar el tamano maximo de request (multipart 5MB, form post 1MB). (01/05/2026)

---

## Checklist final antes de cada entrega de hito

Ejecutar esta lista antes de hacer push al repositorio de entrega:

- [ ] No hay secretos hardcodeados en ningun archivo Java o Dart (buscar con: `grep -r "password\|secret\|token" src/ --include="*.java" | grep -v "test\|//"`).
- [ ] CORS no usa wildcard `*`.
- [ ] Todos los endpoints tienen `@PreAuthorize` explicito (ninguno usa solo `isAuthenticated()` sin razon justificada).
- [ ] Los DTOs de entrada tienen validaciones `@Valid` con restricciones de tamano y formato.
- [ ] Ningun mensaje de error expone informacion interna (traza de stack, nombre de tabla, query SQL).
- [ ] Los logs no contienen datos de usuarios (solo IDs, nunca emails, nombres o contrasenas).
- [ ] La aplicacion arranca sin el perfil `dev` activo en el entorno de produccion.
- [ ] Ejecutar `/owasp-security` sobre los archivos cambiados y resolver issues antes del push.

---

## Referencia rapida — OWASP Top 10 (2021) vs codigo Nexus

| OWASP | Descripcion | Estado en Nexus | Prioridad |
|-------|-------------|-----------------|-----------|
| A01 | Broken Access Control | ✅ CORS, SpEL, IDOR tests A01.2+A01.3 | OK |
| A02 | Cryptographic Failures | ✅ JWT Base64 + BCrypt12 + @Pattern password | Pendiente: HTTPS prod |
| A03 | Injection | nuevoEstado validado en servicio (Set cerrado) | Pendiente: enum SeguimientoEstado |
| A04 | Insecure Design | ✅ RateLimit auth + limite 1 parte/semana | Pendiente: test 429 |
| A05 | Security Misconfiguration | ✅ headers nginx + payload limits | Pendiente: SQL logs prod |
| A06 | Vulnerable Components | Stack actualizado | OK |
| A07 | Auth Failures | Account enum + logout inefectivo | ALTO |
| A08 | Software Integrity | Flyway + multi-stage Docker | OK |
| A09 | Logging & Monitoring | Sin logs de seguridad | ALTO |
| A10 | SSRF | No hay requests externos | OK |
