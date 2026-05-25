-- V21__Demo_Realista.sql
-- Repoblación completa con datos realistas para la demo final del TFG.
-- Contraseña única para todos los usuarios: Demo@Nexus2026
-- Preserva: centros, roles, flyway_schema_history.

-- -----------------------------------------------------------------------
-- 0. Limpiar todos los datos anteriores
-- -----------------------------------------------------------------------
TRUNCATE TABLE
    audit_logs,
    evaluacion_final,
    mensajes,
    notificaciones,
    ausencias,
    incidencias,
    seguimientos,
    practicas,
    usuario_roles,
    usuarios,
    empresas
RESTART IDENTITY CASCADE;

-- -----------------------------------------------------------------------
-- 1. Empresas
-- -----------------------------------------------------------------------
INSERT INTO empresas (nombre, cif, direccion, email_contacto, telefono_contacto) VALUES
    ('Verisure España S.L.',  'B82345678', 'Calle Rosario Pino 14-16, Madrid',    'practicas@verisure.es',   '900374099'),
    ('Indra Sistemas S.A.',   'A28599336', 'Avenida de Bruselas 35, Alcobendas',  'practicas@indra.es',      '917276000'),
    ('Deloitte España S.L.',  'B82982609', 'Plaza Pablo Ruiz Picasso 1, Madrid',  'practicas@deloitte.es',   '915145000'),
    ('Telefónica S.A.',       'A82018474', 'Gran Vía 28, Madrid',                 'practicas@telefonica.es', '912286900');

-- -----------------------------------------------------------------------
-- 2. Admin
-- -----------------------------------------------------------------------
INSERT INTO usuarios (dni, nombre, apellidos, email, password_hash, centro_id, activo) VALUES
    ('10101010J', 'Fuencisla', 'López García',
     'fuencisla@nexus.edu',
     crypt('Demo@Nexus2026', gen_salt('bf', 10)),
     (SELECT id FROM centros LIMIT 1), true);

INSERT INTO usuario_roles (usuario_id, rol_id) VALUES
    ((SELECT id FROM usuarios WHERE dni = '10101010J'), 4);

-- -----------------------------------------------------------------------
-- 3. Tutores de centro
-- -----------------------------------------------------------------------
INSERT INTO usuarios (dni, nombre, apellidos, email, password_hash, centro_id, activo) VALUES
    ('21212121B', 'David',            'Valbuena Segura',    'david.valbuena@nexus.edu',  crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('32323232C', 'Francisco Javier', 'Camarero Moles',     'fj.camarero@nexus.edu',     crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('43434343D', 'Javier',           'Gordillo Pintos',    'javier.gordillo@nexus.edu', crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('54545454E', 'Ramses',           'Muñoz Herrera',      'ramses.munoz@nexus.edu',    crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true);

INSERT INTO usuario_roles (usuario_id, rol_id) VALUES
    ((SELECT id FROM usuarios WHERE dni = '21212121B'), 2),
    ((SELECT id FROM usuarios WHERE dni = '32323232C'), 2),
    ((SELECT id FROM usuarios WHERE dni = '43434343D'), 2),
    ((SELECT id FROM usuarios WHERE dni = '54545454E'), 2);

-- -----------------------------------------------------------------------
-- 4. Tutores de empresa
-- -----------------------------------------------------------------------
INSERT INTO usuarios (dni, nombre, apellidos, email, password_hash, centro_id, activo) VALUES
    ('65656565F', 'Elena',        'Torres Sandoval',   'elena.torres@nexus.edu',    crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('76767676G', 'Miguel Ángel', 'Ruiz Fernández',    'miguel.ruiz@nexus.edu',     crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('87878787H', 'Sofía',        'Domínguez Varela',  'sofia.dominguez@nexus.edu', crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('98989898I', 'Carlos',       'Bermejo Sánchez',   'carlos.bermejo@nexus.edu',  crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true);

INSERT INTO usuario_roles (usuario_id, rol_id) VALUES
    ((SELECT id FROM usuarios WHERE dni = '65656565F'), 3),
    ((SELECT id FROM usuarios WHERE dni = '76767676G'), 3),
    ((SELECT id FROM usuarios WHERE dni = '87878787H'), 3),
    ((SELECT id FROM usuarios WHERE dni = '98989898I'), 3);

-- -----------------------------------------------------------------------
-- 5. Alumnos
-- -----------------------------------------------------------------------
INSERT INTO usuarios (dni, nombre, apellidos, email, password_hash, centro_id, activo) VALUES
    ('11223344K', 'Iker',      'Acevedo Donate',  'iker.acevedo@nexus.edu',    crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('22334455L', 'Iris',      'Pérez Aparicio',  'iris.perez@nexus.edu',      crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('33445566M', 'Rafael',    'Medina Ayuso',    'rafael.medina@nexus.edu',   crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('44556677N', 'Marcos',    'Pérez García',    'marcos.perez@nexus.edu',    crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('55667788P', 'Alejandro', 'Tovar Barroso',   'alejandro.tovar@nexus.edu', crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('66778899Q', 'Natalia',   'Fuentes Molina',  'natalia.fuentes@nexus.edu', crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('77889900R', 'Daniel',    'Herrera Ponce',   'daniel.herrera@nexus.edu',  crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true),
    ('88990011S', 'Carmen',    'Alonso Vidal',    'carmen.alonso@nexus.edu',   crypt('Demo@Nexus2026', gen_salt('bf', 10)), (SELECT id FROM centros LIMIT 1), true);

INSERT INTO usuario_roles (usuario_id, rol_id) VALUES
    ((SELECT id FROM usuarios WHERE dni = '11223344K'), 1),
    ((SELECT id FROM usuarios WHERE dni = '22334455L'), 1),
    ((SELECT id FROM usuarios WHERE dni = '33445566M'), 1),
    ((SELECT id FROM usuarios WHERE dni = '44556677N'), 1),
    ((SELECT id FROM usuarios WHERE dni = '55667788P'), 1),
    ((SELECT id FROM usuarios WHERE dni = '66778899Q'), 1),
    ((SELECT id FROM usuarios WHERE dni = '77889900R'), 1),
    ((SELECT id FROM usuarios WHERE dni = '88990011S'), 1);

-- -----------------------------------------------------------------------
-- 6. Prácticas (8 ACTIVAS — una por alumno)
-- -----------------------------------------------------------------------

-- FCT-2026-001: Iker → David Valbuena + Elena Torres (Verisure)  ← DEMO PRINCIPAL
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id, empresa_id, fecha_inicio, fecha_fin, horas_totales, estado) VALUES
    ('FCT-2026-001',
     (SELECT id FROM usuarios WHERE dni = '11223344K'),
     (SELECT id FROM usuarios WHERE dni = '21212121B'),
     (SELECT id FROM usuarios WHERE dni = '65656565F'),
     (SELECT id FROM empresas WHERE cif = 'B82345678'),
     '2026-01-13', '2026-06-30', 400, 'ACTIVA');

-- FCT-2026-002: Iris → David Valbuena + Elena Torres (Verisure)
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id, empresa_id, fecha_inicio, fecha_fin, horas_totales, estado) VALUES
    ('FCT-2026-002',
     (SELECT id FROM usuarios WHERE dni = '22334455L'),
     (SELECT id FROM usuarios WHERE dni = '21212121B'),
     (SELECT id FROM usuarios WHERE dni = '65656565F'),
     (SELECT id FROM empresas WHERE cif = 'B82345678'),
     '2026-01-13', '2026-06-30', 400, 'ACTIVA');

-- FCT-2026-003: Rafael → David Valbuena + Miguel Ruiz (Indra)
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id, empresa_id, fecha_inicio, fecha_fin, horas_totales, estado) VALUES
    ('FCT-2026-003',
     (SELECT id FROM usuarios WHERE dni = '33445566M'),
     (SELECT id FROM usuarios WHERE dni = '21212121B'),
     (SELECT id FROM usuarios WHERE dni = '76767676G'),
     (SELECT id FROM empresas WHERE cif = 'A28599336'),
     '2026-01-13', '2026-06-30', 400, 'ACTIVA');

-- FCT-2026-004: Marcos → FJ Camarero + Elena Torres (Verisure)
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id, empresa_id, fecha_inicio, fecha_fin, horas_totales, estado) VALUES
    ('FCT-2026-004',
     (SELECT id FROM usuarios WHERE dni = '44556677N'),
     (SELECT id FROM usuarios WHERE dni = '32323232C'),
     (SELECT id FROM usuarios WHERE dni = '65656565F'),
     (SELECT id FROM empresas WHERE cif = 'B82345678'),
     '2026-01-13', '2026-06-30', 400, 'ACTIVA');

-- FCT-2026-005: Alejandro → FJ Camarero + Sofía Domínguez (Deloitte)
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id, empresa_id, fecha_inicio, fecha_fin, horas_totales, estado) VALUES
    ('FCT-2026-005',
     (SELECT id FROM usuarios WHERE dni = '55667788P'),
     (SELECT id FROM usuarios WHERE dni = '32323232C'),
     (SELECT id FROM usuarios WHERE dni = '87878787H'),
     (SELECT id FROM empresas WHERE cif = 'B82982609'),
     '2026-01-13', '2026-06-30', 400, 'ACTIVA');

-- FCT-2026-006: Natalia → Javier Gordillo + Sofía Domínguez (Deloitte)
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id, empresa_id, fecha_inicio, fecha_fin, horas_totales, estado) VALUES
    ('FCT-2026-006',
     (SELECT id FROM usuarios WHERE dni = '66778899Q'),
     (SELECT id FROM usuarios WHERE dni = '43434343D'),
     (SELECT id FROM usuarios WHERE dni = '87878787H'),
     (SELECT id FROM empresas WHERE cif = 'B82982609'),
     '2026-01-13', '2026-06-30', 400, 'ACTIVA');

-- FCT-2026-007: Daniel → Javier Gordillo + Carlos Bermejo (Telefónica)
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id, empresa_id, fecha_inicio, fecha_fin, horas_totales, estado) VALUES
    ('FCT-2026-007',
     (SELECT id FROM usuarios WHERE dni = '77889900R'),
     (SELECT id FROM usuarios WHERE dni = '43434343D'),
     (SELECT id FROM usuarios WHERE dni = '98989898I'),
     (SELECT id FROM empresas WHERE cif = 'A82018474'),
     '2026-01-13', '2026-06-30', 400, 'ACTIVA');

-- FCT-2026-008: Carmen → Ramses Muñoz + Carlos Bermejo (Telefónica)
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id, empresa_id, fecha_inicio, fecha_fin, horas_totales, estado) VALUES
    ('FCT-2026-008',
     (SELECT id FROM usuarios WHERE dni = '88990011S'),
     (SELECT id FROM usuarios WHERE dni = '54545454E'),
     (SELECT id FROM usuarios WHERE dni = '98989898I'),
     (SELECT id FROM empresas WHERE cif = 'A82018474'),
     '2026-01-13', '2026-06-30', 400, 'ACTIVA');

-- -----------------------------------------------------------------------
-- 7. Seguimientos — FCT-2026-001 (Iker, DEMO PRINCIPAL)
--    5 COMPLETADO + 1 PENDIENTE_CENTRO + 1 PENDIENTE_EMPRESA
-- -----------------------------------------------------------------------
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado, validado_por) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'), '2026-01-20', 8.0,
     'Primera semana en Verisure España. Onboarding: accesos a sistemas, presentación del equipo y herramientas. Revisión del stack tecnológico (Java, Angular, AWS).',
     'COMPLETADO',
     (SELECT id FROM usuarios WHERE dni = '21212121B')),

    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'), '2026-01-27', 8.0,
     'Formación en los sistemas de alarma y monitorización de Verisure. Estudio de la arquitectura de microservicios del backend de gestión de dispositivos.',
     'COMPLETADO',
     (SELECT id FROM usuarios WHERE dni = '21212121B')),

    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'), '2026-02-03', 8.0,
     'Desarrollo del módulo de gestión de alertas: API REST con Spring Boot para registrar y consultar eventos de los sensores. Tests unitarios con JUnit 5.',
     'COMPLETADO',
     (SELECT id FROM usuarios WHERE dni = '21212121B')),

    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'), '2026-02-10', 8.0,
     'Integración del backend con el CRM interno. Implementación del conector para sincronizar el estado de las instalaciones con el sistema de atención al cliente.',
     'COMPLETADO',
     (SELECT id FROM usuarios WHERE dni = '21212121B')),

    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'), '2026-02-17', 8.0,
     'Refactorización del módulo de reportes: migración de SQL nativo a JPA Criteria API. Mejora del rendimiento en un 40% según las pruebas de carga realizadas.',
     'COMPLETADO',
     (SELECT id FROM usuarios WHERE dni = '21212121B')),

    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'), '2026-02-24', 8.0,
     'Desarrollo del panel de monitorización en Angular. Componentes de gráficas en tiempo real con Chart.js para visualizar el estado de las instalaciones activas.',
     'PENDIENTE_CENTRO', NULL),

    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'), '2026-03-03', 8.0,
     'Implementación del sistema de notificaciones push para el panel de operadores. Integración con Firebase Cloud Messaging para alertas críticas en tiempo real.',
     'PENDIENTE_EMPRESA', NULL);

-- -----------------------------------------------------------------------
-- 8. Seguimientos — resto de alumnos
-- -----------------------------------------------------------------------

-- Iris (FCT-2026-002)
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-002'), '2026-01-20', 8.0,
     'Incorporación al equipo de Verisure. Configuración del entorno y formación en protocolos de seguridad de la información.', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-002'), '2026-01-27', 8.0,
     'Desarrollo de scripts de automatización para pruebas de regresión del sistema de alarmas.', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-002'), '2026-02-03', 8.0,
     'Implementación de tests de integración para el módulo de gestión de clientes.', 'PENDIENTE_CENTRO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-002'), '2026-02-10', 8.0,
     'Análisis de incidencias recurrentes en el sistema de monitorización nocturna.', 'PENDIENTE_EMPRESA');

-- Rafael (FCT-2026-003)
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-003'), '2026-01-20', 8.0,
     'Inicio en Indra. Formación en metodología SCRUM y herramientas corporativas (Jira, Confluence, GitLab).', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-003'), '2026-01-27', 8.0,
     'Desarrollo de módulos para el sistema de gestión de proyectos de defensa. Backend Java con Spring Boot.', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-003'), '2026-02-03', 8.0,
     'Participación en sprint review. Presentación de los módulos desarrollados al cliente interno.', 'PENDIENTE_EMPRESA');

-- Marcos (FCT-2026-004)
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-004'), '2026-01-20', 8.0,
     'Incorporación a Verisure. Formación en el stack tecnológico y procesos internos del equipo de producto.', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-004'), '2026-01-27', 8.0,
     'Desarrollo de componentes del panel de gestión de instalaciones en React.', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-004'), '2026-02-03', 8.0,
     'Optimización de consultas SQL en el servicio de reportes. Reducción del tiempo de respuesta en un 30%.', 'PENDIENTE_CENTRO');

-- Alejandro (FCT-2026-005)
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-005'), '2026-01-20', 8.0,
     'Inicio en Deloitte. Onboarding y formación en metodologías de consultoría y auditoría tecnológica.', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-005'), '2026-01-27', 8.0,
     'Participación en proyecto de transformación digital para cliente del sector financiero.', 'PENDIENTE_EMPRESA');

-- Natalia (FCT-2026-006)
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-006'), '2026-01-20', 8.0,
     'Incorporación a Deloitte. Revisión de documentación técnica y procesos del área de consultoría de negocio.', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-006'), '2026-01-27', 8.0,
     'Análisis de requisitos para proyecto de migración cloud de cliente del sector retail.', 'PENDIENTE_CENTRO');

-- Daniel (FCT-2026-007)
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-007'), '2026-01-20', 8.0,
     'Inicio en Telefónica. Formación en infraestructura de red, sistemas de comunicaciones y herramientas NOC.', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-007'), '2026-01-27', 8.0,
     'Configuración y pruebas de equipos de red en el laboratorio del área de operaciones.', 'PENDIENTE_EMPRESA');

-- Carmen (FCT-2026-008)
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-008'), '2026-01-20', 8.0,
     'Incorporación a Telefónica. Introducción a los sistemas de gestión de incidencias de red y herramientas ITSM.', 'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-008'), '2026-01-27', 8.0,
     'Monitorización de la infraestructura de red y registro de incidencias en el sistema corporativo Remedy.', 'COMPLETADO');

-- -----------------------------------------------------------------------
-- 9. Incidencias
-- -----------------------------------------------------------------------

-- Iker: ABIERTA — solicitud de acceso a repositorio
INSERT INTO incidencias (practica_id, creada_por, tipo, descripcion, estado) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'),
     (SELECT id FROM usuarios WHERE dni = '11223344K'),
     'ACCESO',
     'Sin acceso al repositorio privado del módulo de facturación. El equipo de desarrollo me indica que debo solicitarlo a través del tutor del centro para que lo gestione con RRHH de Verisure.',
     'ABIERTA');

-- Rafael: RESUELTA — ausencia justificada
INSERT INTO incidencias (practica_id, creada_por, tipo, descripcion, estado, resuelta_por, fecha_resolucion) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-003'),
     (SELECT id FROM usuarios WHERE dni = '33445566M'),
     'AUSENCIA',
     'Ausencia el 28/01/2026 por cita médica urgente. Justificante adjunto.',
     'RESUELTA',
     (SELECT id FROM usuarios WHERE dni = '21212121B'),
     '2026-01-30 10:00:00');

-- Alejandro: ABIERTA — solicitud de cambio de horario
INSERT INTO incidencias (practica_id, creada_por, tipo, descripcion, estado) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-005'),
     (SELECT id FROM usuarios WHERE dni = '55667788P'),
     'OTROS',
     'Solicito modificación de horario de mañana (9:00-14:00) a tarde (15:00-20:00) por incompatibilidad con exámenes de recuperación en el centro. La empresa confirma disponibilidad en turno de tarde.',
     'ABIERTA');

-- -----------------------------------------------------------------------
-- 10. Ausencias (Iker — 2 justificadas)
-- -----------------------------------------------------------------------
INSERT INTO ausencias (practica_id, fecha, motivo, tipo, registrada_por_id, revisada_por_id, comentario_revision) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'),
     '2026-02-05',
     'Cita médica programada. Justificante entregado al tutor del centro.',
     'JUSTIFICADA',
     (SELECT id FROM usuarios WHERE dni = '11223344K'),
     (SELECT id FROM usuarios WHERE dni = '21212121B'),
     'Justificante revisado y validado.'),

    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-001'),
     '2026-02-26',
     'Asistencia a jornada de orientación laboral organizada por el centro educativo.',
     'JUSTIFICADA',
     (SELECT id FROM usuarios WHERE dni = '11223344K'),
     (SELECT id FROM usuarios WHERE dni = '21212121B'),
     'Actividad académica autorizada por el centro.');

-- -----------------------------------------------------------------------
-- 11. Evaluaciones finales
--     Solo para Carmen y Daniel — Iker queda sin evaluar para demostrarlo en vídeo
-- -----------------------------------------------------------------------

-- Carmen (FCT-2026-008) evaluada por Carlos Bermejo
INSERT INTO evaluacion_final (practica_id, tutor_empresa_id,
    actitud_puntualidad, competencia_tecnica, iniciativa_autonomia,
    trabajo_equipo, cumplimiento_tareas, nota_global, comentario) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-008'),
     (SELECT id FROM usuarios WHERE dni = '98989898I'),
     8.5, 7.5, 8.0, 8.5, 8.0,
     8.10,
     'Carmen ha demostrado una actitud excelente y gran capacidad de adaptación. Muy puntual y comprometida con las tareas asignadas.');

-- Daniel (FCT-2026-007) evaluado por Carlos Bermejo
INSERT INTO evaluacion_final (practica_id, tutor_empresa_id,
    actitud_puntualidad, competencia_tecnica, iniciativa_autonomia,
    trabajo_equipo, cumplimiento_tareas, nota_global, comentario) VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2026-007'),
     (SELECT id FROM usuarios WHERE dni = '98989898I'),
     7.0, 8.5, 7.5, 7.0, 8.0,
     7.60,
     'Daniel muestra buenos conocimientos técnicos de redes. Debe mejorar la proactividad y la comunicación con el equipo.');
