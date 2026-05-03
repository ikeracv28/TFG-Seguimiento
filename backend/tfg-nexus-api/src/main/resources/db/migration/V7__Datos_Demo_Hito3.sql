-- V7__Datos_Demo_Hito3.sql
-- Datos de demostración para el Hito 3.
-- Añade 2 empresas, 3 tutores nuevos, 3 alumnos nuevos,
-- 3 prácticas adicionales (ACTIVA / BORRADOR / FINALIZADA),
-- seguimientos e incidencias variados.
-- Contraseña de todos los usuarios nuevos: Prueba@Nexus2026

-- -----------------------------------------------------------------------
-- 1. Empresas adicionales
-- -----------------------------------------------------------------------
INSERT INTO empresas (nombre, cif, direccion, email_contacto, telefono_contacto)
VALUES
    ('InnovateTech S.A.', 'A87654321', 'Avenida de la Innovación, 12, Barcelona',
     'practicas@innovatetech.es', '932345678'),
    ('DataSystems S.L.', 'B98765432', 'Calle Datos, 7, Valencia',
     'rrhh@datasystems.es', '963456789');

-- -----------------------------------------------------------------------
-- 2. Nuevos tutores de empresa
-- -----------------------------------------------------------------------
INSERT INTO usuarios (dni, nombre, apellidos, email, password_hash, centro_id, activo)
VALUES
    ('55555555E', 'María', 'López Romero',
     'tutorempresa2@nexus.edu',
     crypt('Prueba@Nexus2026', gen_salt('bf', 10)),
     (SELECT id FROM centros LIMIT 1), true),

    ('66666666F', 'Pedro', 'Ruiz Navarro',
     'tutorempresa3@nexus.edu',
     crypt('Prueba@Nexus2026', gen_salt('bf', 10)),
     (SELECT id FROM centros LIMIT 1), true);

INSERT INTO usuario_roles (usuario_id, rol_id)
VALUES
    ((SELECT id FROM usuarios WHERE email = 'tutorempresa2@nexus.edu'), 3),
    ((SELECT id FROM usuarios WHERE email = 'tutorempresa3@nexus.edu'), 3);

-- -----------------------------------------------------------------------
-- 3. Nuevo tutor de centro
-- -----------------------------------------------------------------------
INSERT INTO usuarios (dni, nombre, apellidos, email, password_hash, centro_id, activo)
VALUES
    ('77777777G', 'Ana', 'Martínez Vega',
     'tutor2@nexus.edu',
     crypt('Prueba@Nexus2026', gen_salt('bf', 10)),
     (SELECT id FROM centros LIMIT 1), true);

INSERT INTO usuario_roles (usuario_id, rol_id)
VALUES
    ((SELECT id FROM usuarios WHERE email = 'tutor2@nexus.edu'), 2);

-- -----------------------------------------------------------------------
-- 4. Nuevos alumnos
-- -----------------------------------------------------------------------
INSERT INTO usuarios (dni, nombre, apellidos, email, password_hash, centro_id, activo)
VALUES
    ('88888888H', 'Carlos', 'Pérez Moreno',
     'alumno2@nexus.edu',
     crypt('Prueba@Nexus2026', gen_salt('bf', 10)),
     (SELECT id FROM centros LIMIT 1), true),

    ('99999999I', 'Laura', 'García Blanco',
     'alumno3@nexus.edu',
     crypt('Prueba@Nexus2026', gen_salt('bf', 10)),
     (SELECT id FROM centros LIMIT 1), true),

    ('10101010J', 'Diego', 'Sánchez Torres',
     'alumno4@nexus.edu',
     crypt('Prueba@Nexus2026', gen_salt('bf', 10)),
     (SELECT id FROM centros LIMIT 1), true);

INSERT INTO usuario_roles (usuario_id, rol_id)
VALUES
    ((SELECT id FROM usuarios WHERE email = 'alumno2@nexus.edu'), 1),
    ((SELECT id FROM usuarios WHERE email = 'alumno3@nexus.edu'), 1),
    ((SELECT id FROM usuarios WHERE email = 'alumno4@nexus.edu'), 1);

-- -----------------------------------------------------------------------
-- 5. Prácticas adicionales
-- -----------------------------------------------------------------------

-- FCT-2025-002: ACTIVA — Carlos en InnovateTech
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id,
                        empresa_id, fecha_inicio, fecha_fin, horas_totales, estado)
VALUES (
    'FCT-2025-002',
    (SELECT id FROM usuarios WHERE email = 'alumno2@nexus.edu'),
    (SELECT id FROM usuarios WHERE email = 'tutor@nexus.edu'),
    (SELECT id FROM usuarios WHERE email = 'tutorempresa2@nexus.edu'),
    (SELECT id FROM empresas WHERE cif = 'A87654321'),
    '2025-04-07', '2025-11-07', 240, 'ACTIVA'
);

-- FCT-2025-003: BORRADOR — Laura en DataSystems (aún no iniciada)
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id,
                        empresa_id, fecha_inicio, fecha_fin, horas_totales, estado)
VALUES (
    'FCT-2025-003',
    (SELECT id FROM usuarios WHERE email = 'alumno3@nexus.edu'),
    (SELECT id FROM usuarios WHERE email = 'tutor2@nexus.edu'),
    (SELECT id FROM usuarios WHERE email = 'tutorempresa3@nexus.edu'),
    (SELECT id FROM empresas WHERE cif = 'B98765432'),
    '2025-05-05', '2025-12-05', 200, 'BORRADOR'
);

-- FCT-2025-004: FINALIZADA — Diego en InnovateTech (ya terminada)
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id,
                        empresa_id, fecha_inicio, fecha_fin, horas_totales, estado)
VALUES (
    'FCT-2025-004',
    (SELECT id FROM usuarios WHERE email = 'alumno4@nexus.edu'),
    (SELECT id FROM usuarios WHERE email = 'tutor2@nexus.edu'),
    (SELECT id FROM usuarios WHERE email = 'tutorempresa2@nexus.edu'),
    (SELECT id FROM empresas WHERE cif = 'A87654321'),
    '2024-10-01', '2025-03-28', 220, 'FINALIZADA'
);

-- -----------------------------------------------------------------------
-- 6. Seguimientos para FCT-2025-002 (Carlos, ACTIVA)
-- -----------------------------------------------------------------------
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado)
VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2025-002'),
     '2025-04-14', 8,
     'Primera semana. Onboarding en InnovateTech: accesos, herramientas y metodología ágil del equipo.',
     'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2025-002'),
     '2025-04-21', 8,
     'Segunda semana. Desarrollo de componentes React para el módulo de facturación.',
     'VALIDADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2025-002'),
     '2025-04-28', 8,
     'Tercera semana. Integración de API REST con el frontend. Tests unitarios.',
     'PENDIENTE');

-- -----------------------------------------------------------------------
-- 7. Seguimientos para FCT-2025-004 (Diego, FINALIZADA — historial completo)
-- -----------------------------------------------------------------------
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas, descripcion, estado)
VALUES
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2025-004'),
     '2024-10-07', 8,
     'Inicio de prácticas. Configuración del entorno de trabajo y presentación al equipo.',
     'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2025-004'),
     '2024-10-14', 8,
     'Desarrollo del módulo de usuarios. CRUD completo con Spring Boot.',
     'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2025-004'),
     '2024-10-21', 8,
     'Implementación de tests de integración. Cobertura del 80% en el servicio principal.',
     'COMPLETADO'),
    ((SELECT id FROM practicas WHERE codigo = 'FCT-2025-004'),
     '2024-10-28', 8,
     'Despliegue en entorno de staging con Docker. Documentación técnica.',
     'COMPLETADO');

-- -----------------------------------------------------------------------
-- 8. Incidencias variadas
-- -----------------------------------------------------------------------

-- Incidencia resuelta en la práctica finalizada
INSERT INTO incidencias (practica_id, creada_por, tipo, descripcion, estado,
                          resuelta_por, fecha_resolucion)
VALUES (
    (SELECT id FROM practicas WHERE codigo = 'FCT-2025-004'),
    (SELECT id FROM usuarios WHERE email = 'alumno4@nexus.edu'),
    'AUSENCIA',
    'El alumno no pudo asistir el 15/10/2024 por enfermedad. Adjunta justificante médico.',
    'RESUELTA',
    (SELECT id FROM usuarios WHERE email = 'tutor2@nexus.edu'),
    '2024-10-16 09:00:00'
);

-- Incidencia abierta en la práctica activa de Carlos
INSERT INTO incidencias (practica_id, creada_por, tipo, descripcion, estado)
VALUES (
    (SELECT id FROM practicas WHERE codigo = 'FCT-2025-002'),
    (SELECT id FROM usuarios WHERE email = 'alumno2@nexus.edu'),
    'OTROS',
    'El alumno solicita cambio de horario de mañana a tarde por compatibilidad con clases en el centro.',
    'ABIERTA'
);
