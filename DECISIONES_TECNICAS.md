# Decisiones Técnicas Registradas

## Backend

**Flyway sobre `ddl-auto=update`**: Control total y auditable. `update` puede destruir datos en producción sin aviso.

**MapStruct sobre mapeo manual**: Genera código en compilación sin reflection. Los errores aparecen en compilación, no en runtime.

**`@EqualsAndHashCode(of = "id")` sobre `@Data`**: `@Data` rompe JPA con relaciones lazy y provoca StackOverflowError.

**WebSocket/STOMP para el chat**: REST con polling tiene latencia inaceptable. STOMP es el estándar en Spring Boot para mensajería en tiempo real.

**JWT con JTI + blacklist en memoria (ConcurrentHashMap)**: La blacklist en BD (tabla token_revocado) es más robusta pero innecesaria para el TFG. La blacklist en memoria se pierde al reiniciar, pero los tokens expiran naturalmente. En producción: Redis con TTL.

**Doble validación de seguimientos (18/04/2025)**: La validación simple no refleja la realidad de las FCT. Existe la firma del tutor de empresa (valida el trabajo real) y la supervisión del tutor del centro (valida lo formativo). El rechazo genera incidencia automática para proteger al alumno.

## Frontend

**Provider sobre Riverpod**: Suficiente para el TFG, más sencillo de justificar en la memoria.

**Sistema visual Nexus (18/04/2025)**: Diseño limpio estilo Notion/Linear. Color semántico obligatorio. Adaptativo web/móvil con LayoutBuilder. Todo centralizado en `app_theme.dart`.

## Seguridad

**JWT secret con `Decoders.BASE64.decode()`**: `secret.getBytes()` trata los caracteres Base64 literales como bytes, no los bytes reales que representan. La corrección invalida tokens anteriores.

**Contraseñas BCrypt cost=10**: Equilibrio entre seguridad y rendimiento de login en un servidor de TFG.

## Contexto del Evaluador

El tutor corrige con dos IAs: una local entrenada por él y Claude en la nube.

Valora: arquitectura por capas limpia, JWT funcional con roles, decisiones justificadas, tests reales con casos de negocio, coherencia doc/código, sin secretos en repo.

Penaliza: inconsistencias doc/código, excepciones genéricas con info interna, features en la memoria inexistentes en el código, código sin tests.
