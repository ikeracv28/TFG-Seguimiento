# Contenido nuevo para la Memoria TFG — Nexus
> Pega cada sección en el lugar correspondiente del Word

---

## → SECCIÓN 3.1 — Añadir al final de la lista de Requisitos Funcionales

- **RF-08 (Gestión de Ausencias):** El sistema debe permitir al alumno registrar ausencias durante el periodo de prácticas, indicando fecha y motivo, con posibilidad de adjuntar un justificante en formato PDF, JPG o PNG. El tutor de empresa las revisa y las marca como justificadas o injustificadas.
- **RF-09 (Panel de Administración):** El administrador debe poder crear, editar y desactivar usuarios de todos los roles, así como gestionar las prácticas activas. Toda acción queda registrada en un log de auditoría trazable.
- **RF-10 (Trazabilidad de acciones):** El sistema debe registrar automáticamente todas las operaciones relevantes —creación y edición de usuarios y prácticas, registro de ausencias e incidencias, validaciones de seguimientos— en un log de auditoría accesible solo por el administrador.
- **RF-11 (Chat en tiempo real):** Cada práctica activa dispone de un canal de mensajería privado entre el alumno, el tutor del centro y el tutor de empresa, con historial persistente y entrega de mensajes en tiempo real mediante protocolo WebSocket/STOMP.

---

## → SECCIÓN 4.1 — Añadir a continuación del texto actual del backend

### Módulo de ausencias

La implementación del módulo de ausencias surgió de detectar que la plataforma registraba el trabajo realizado pero no las faltas de asistencia, que tienen consecuencias distintas sobre el cómputo de horas y la calificación final. Diseñé una tabla independiente en lugar de añadir campos a la tabla de seguimientos existente, porque una ausencia no tiene horas ni descripción de tareas pero sí un fichero adjunto de justificante. Mezclar ambos conceptos habría generado columnas siempre nulas según el tipo de registro, lo que en un modelo relacional indica normalización incorrecta.

El justificante se almacena como `bytea` directamente en PostgreSQL, vinculado al registro de la ausencia. Esta decisión evita la complejidad de gestionar un sistema de ficheros externo para el alcance del proyecto. La respuesta JSON expone solo un campo booleano `tieneJustificante`, de modo que el cliente sabe si existe un fichero sin descargarlo hasta que el usuario lo solicite. El endpoint de descarga verifica antes de devolver los bytes que quien solicita sea participante de la práctica vinculada a esa ausencia.

### Panel de administración y sistema de auditoría

El panel de administración permite crear usuarios de todos los roles, editarlos y activarlos o desactivarlos, y también crear y modificar las prácticas activas. La capacidad de edición fue una adición razonada tras analizar los errores más frecuentes durante el despliegue: escribir mal un email o asignar un alumno a la práctica equivocada son errores habituales que no deberían requerir borrar el registro entero para corregirlos. Durante la implementación encontré un error sutil: el servicio usaba `Set.of()` de Java para asignar el nuevo rol al usuario, que devuelve una colección inmutable. Cuando Hibernate intentaba sincronizar la relación `@ManyToMany` de roles llamaba a `clear()` sobre esa colección y lanzaba una `UnsupportedOperationException`. La corrección fue operar directamente sobre la colección gestionada por Hibernate —`getRoles().clear()` seguido de `getRoles().add(nuevoRol)`— en lugar de sustituir la referencia. Es el tipo de error que parece correcto al leer el código pero solo falla en runtime cuando el framework intenta modificar la colección.

El sistema de auditoría centraliza en la tabla `audit_logs` el registro de todas las operaciones relevantes: usuarios, prácticas, ausencias, incidencias, seguimientos y mensajes de chat. El servicio `AuditService` utiliza `Propagation.REQUIRES_NEW` para que el log de auditoría se guarde en una transacción independiente de la operación principal. Esto garantiza que incluso si la operación falla y su transacción hace rollback, el intento queda registrado —que es exactamente el comportamiento que se necesita en un sistema de trazabilidad.

---

## → NUEVA SECCIÓN 4.2 — Seguridad aplicada: revisión sistemática OWASP

Durante el tercer hito realicé una revisión de seguridad estructurada siguiendo el estándar OWASP Top 10 (2021), aplicando las correcciones directamente al código en lugar de dejarlas para una fase final. Recojo a continuación las decisiones más relevantes.

**Control de acceso (A01).** Varios controladores REST incluían `@CrossOrigin(origins = "*")`, que permite peticiones desde cualquier origen y anula la protección CORS frente a peticiones maliciosas. Eliminé estas anotaciones y centralicé la configuración en `SecurityConfig`, especificando solo los orígenes legítimos. También corregí dos expresiones de `@PreAuthorize` que referenciaban una propiedad inexistente del objeto `UserDetails`; las sustituí por llamadas al servicio que verifican si el usuario autenticado es participante de la práctica solicitada.

**Fallos criptográficos (A02).** El método de firma JWT usaba `secret.getBytes()` para obtener la clave. Como el secreto está en Base64, `getBytes()` trata los caracteres de esa codificación como bytes literales, no los bytes reales que representan. La corrección fue `Decoders.BASE64.decode(secret)`. Los tokens generados con el método antiguo son incompatibles con los del nuevo, lo que obligó a invalidar las sesiones durante el despliegue del fix. Además reforcé la política de contraseñas con `@Pattern` en el DTO de registro: mayúscula, minúscula, dígito, carácter especial y mínimo diez caracteres.

**Diseño inseguro (A04).** El servicio de seguimientos no impedía registrar varios partes en la misma semana ISO, lo que generaría inconsistencias en el cómputo de horas. Añadí la comprobación sobre la semana (lunes a domingo) antes de permitir un parte nuevo. El módulo de ausencias aplica un control equivalente: no puede existir más de una ausencia para la misma práctica y fecha.

**Fallos de autenticación (A07).** El endpoint de registro devolvía mensajes de error distintos según si el campo duplicado era el email o el DNI, lo que permite enumerar qué datos existen en el sistema. La corrección fue unificar la comprobación y devolver siempre el mismo mensaje genérico. Para el cierre de sesión implementé una blacklist de tokens en servidor: cada JWT incluye un claim `jti` con un UUID único, y al hacer logout ese identificador se registra en memoria. El filtro de autenticación verifica la blacklist antes de aceptar cualquier token, invalidando inmediatamente un token robado aunque no haya caducado.

**Rate limiting y cabeceras (A05).** Un filtro con máxima prioridad en la cadena de Spring Security limita a diez las peticiones de autenticación por IP y minuto, devolviendo HTTP 429 al superarlo. Las cabeceras `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy` y una `Content-Security-Policy` restrictiva se configuraron tanto en Spring Security como en Nginx, cubriendo tanto las respuestas de la API como la carga de la aplicación web.

---

## → NUEVA SECCIÓN 4.3 — Tests automatizados y cobertura de código

Desde el inicio del proyecto traté los tests de integración como parte del desarrollo, no como un añadido opcional. La arquitectura en capas facilita esto: los servicios encapsulan toda la lógica de negocio de forma independiente al protocolo HTTP, lo que permite testearlos directamente con un contexto Spring completo sobre una base de datos H2 en memoria sin necesidad de arrancar el servidor. Al finalizar el tercer hito el proyecto cuenta con ciento siete tests organizados en doce clases. Los tests de servicio usan `@SpringBootTest` con el perfil `test`, que activa H2 con compatibilidad PostgreSQL y desactiva Flyway para que Hibernate genere el esquema. Los tests de controlador usan `@WebMvcTest`, que levanta solo la capa web y permite verificar el comportamiento de seguridad por roles con `@WithMockUser`, comprobando que un endpoint devuelve 403 cuando lo llama un rol sin permiso sin necesidad de hacer una petición real.

Para medir la cobertura configuré JaCoCo, que instrumenta el bytecode en tiempo de compilación. Ejecutar `./mvnw verify` corre todos los tests y genera el informe en `target/site/jacoco/index.html`. La cobertura al cierre del Hito 3 es del 69,5% de instrucciones, con los módulos principales —ausencias, incidencias, administración— por encima del 80%.

Durante la escritura de los tests detecté un error que había pasado desapercibido: la implementación de seguimientos accedía a `SecurityContextHolder.getContext().getAuthentication().getName()` sin verificar si la autenticación era nula. En los tests de integración ese método se llama sin contexto de seguridad activo y lanza un `NullPointerException`. La corrección fue un método privado `currentUserEmail()` que devuelve `"system"` cuando no hay autenticación. Es un ejemplo de cómo la escritura de tests no solo verifica funcionalidad, sino que obliga a revisar el código desde un ángulo diferente y aflora bugs que la ejecución normal no ejercita.

---

## → SECCIÓN 5.2 — Reemplazar el texto actual del Panel del Tutor del Centro

```
● Lista de Alumnos: El tutor puede saltar de un alumno a otro para ver su progreso FCT,
  los partes pendientes de su validación final y las incidencias abiertas.
● Partes pendientes: Vista global de todos los seguimientos que están esperando la validación
  final del centro, sin necesidad de entrar en cada alumno.
● Alertas visuales: Cada alumno en la lista lleva un badge numérico rojo que suma sus
  incidencias abiertas y ausencias injustificadas, para detectar casos que necesitan
  atención sin revisar ficha por ficha.
● Barra de progreso FCT: Muestra las horas completadas frente al total del convenio,
  computando únicamente seguimientos en estado COMPLETADO —los que ya tienen las
  dos validaciones—, evitando inflar el progreso con partes aún pendientes.
```

---

## → NUEVA SECCIÓN 5.5 — Panel de Administración

```
● Gestión de usuarios: Crear usuarios de cualquier rol, editarlos (nombre, email, DNI, rol)
  y activarlos o desactivarlos sin necesidad de eliminar el registro.
● Gestión de prácticas: Crear y modificar prácticas activas, corrigiendo participantes o
  fechas sin borrar y recrear el convenio.
● Auditoría: Historial de todas las operaciones del sistema, filtrable por módulo, con
  el email del actor y la descripción de cada acción. Accesible solo por el administrador.
```

---

## → SECCIÓN 7 — Añadir a continuación del párrafo de Hito 2

**Estado Actual (Entrega Hito 3 — 75%):** El tercer hito concentró el mayor volumen de trabajo del proyecto. Se completaron cuatro bloques funcionales independientes: el módulo de ausencias con su flujo de revisión y gestión de justificantes adjuntos, el panel de administración con edición completa de usuarios y prácticas, el sistema de auditoría centralizado, y una revisión sistemática de seguridad OWASP que resultó en correcciones concretas sobre CORS, firma JWT, política de contraseñas, gestión de sesiones y rate limiting. La batería de tests creció hasta ciento siete casos con cobertura del 69,5% medida con JaCoCo. Dos aspectos merecen mención especial: el error `UnsupportedOperationException` causado por `Set.of()` inmutable en la edición de usuarios —un bug que solo se manifiesta en runtime cuando Hibernate intenta modificar la colección— y la transacción independiente del servicio de auditoría con `Propagation.REQUIRES_NEW`, que garantiza que los intentos fallidos también quedan registrados.

**Estado Actual (Hito 4 — en desarrollo):** El cuarto y último hito implementa el chat en tiempo real mediante WebSocket y el protocolo STOMP. El backend expone un endpoint `/ws` al que Flutter conecta usando `stomp_dart_client`. La autenticación se resuelve pasando el token JWT en las cabeceras del frame STOMP `CONNECT`, que un interceptor de canal valida antes de registrar la conexión. Los mensajes se publican en topics por práctica (`/topic/practica/{id}`) de modo que solo los participantes de cada práctica reciben los mensajes de su chat. El historial se carga mediante REST al abrir la pantalla y los mensajes nuevos llegan por WebSocket en tiempo real. Al ser el último hito antes de la entrega, el chat completará el ciclo de comunicación que era el objetivo central del proyecto desde su definición inicial.

---

## → SECCIÓN 8 — Reemplazar el texto actual de Conclusión

Este proyecto demuestra que se puede mejorar significativamente la experiencia de las prácticas si se centraliza en un único entorno digital lo que antes estaba disperso entre correos, llamadas y hojas de cálculo. La plataforma Nexus cubre el ciclo completo del seguimiento: el registro semanal de actividades, la doble validación por figuras con responsabilidades distintas, la gestión de incidencias y ausencias, y la comunicación directa entre los participantes de cada práctica.

Uno de los aprendizajes más valiosos ha sido comprobar que las decisiones con más impacto no son las tecnológicas sino las de lógica de negocio. Detectar que el flujo de validación necesitaba dos pasos diferenciados antes de construir ninguna pantalla, o que una ausencia y un seguimiento son entidades con naturaleza distinta que no deben compartir tabla, son decisiones que no se ven en la interfaz pero que hacen el sistema correcto y mantenible. La revisión de seguridad OWASP fue igualmente reveladora: algunos problemas como el wildcard CORS o el uso incorrecto de `getBytes()` para la clave JWT son errores que se cometen con naturalidad al seguir tutoriales y solo se detectan cuando se entiende el porqué detrás de cada control.

En cuanto al futuro, la plataforma está pensada para crecer en dos direcciones: a corto plazo, firma digital de convenios y notificaciones push; a medio plazo, la gestión del proceso previo a las prácticas —publicación de perfiles por la empresa, preferencias del alumno y asignación por el centro— que convertiría Nexus en la plataforma completa del ciclo de prácticas de principio a fin.
