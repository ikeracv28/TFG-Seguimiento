-- V4__Datos_Prueba_Hito2.sql
-- Datos de prueba para la demo del Hito 2.
-- Añade empresa, tutor de empresa, práctica activa, seguimientos e incidencia.

-- Habilitar extensión para cifrado si aún no está activa (idempotente)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------
-- 1. Empresa de prácticas
-- -----------------------------------------------------------------------
INSERT INTO empresas (nombre, cif, direccion, email_contacto, telefono_contacto)
VALUES ('EjemploTech S.L.', 'B12345678', 'Calle Tecnología, 5, Madrid',
        'practicas@ejemplotech.es', '911234567');

-- -----------------------------------------------------------------------
-- 2. Usuario tutor de empresa
-- -----------------------------------------------------------------------
INSERT INTO usuarios (dni, nombre, apellidos, email, password_hash, centro_id, activo)
VALUES ('44444444D', 'Carlos', 'García Empresa',
        'tutorempresa@nexus.edu',
        crypt('123456', gen_salt('bf')),
        (SELECT id FROM centros LIMIT 1),
        true);

-- Asignar rol TUTOR_EMPRESA (id = 3 según V2)
INSERT INTO usuario_roles (usuario_id, rol_id)
VALUES ((SELECT id FROM usuarios WHERE dni = '44444444D'), 3);

-- -----------------------------------------------------------------------
-- 3. Práctica activa
-- -----------------------------------------------------------------------
INSERT INTO practicas (codigo, alumno_id, tutor_centro_id, tutor_empresa_id,
                        empresa_id, fecha_inicio, fecha_fin,
                        horas_totales, estado)
VALUES (
    'FCT-2025-001',
    (SELECT id FROM usuarios WHERE email = 'alumno@nexus.edu'),
    (SELECT id FROM usuarios WHERE email = 'tutor@nexus.edu'),
    (SELECT id FROM usuarios WHERE email = 'tutorempresa@nexus.edu'),
    (SELECT id FROM empresas WHERE cif = 'B12345678'),
    '2025-04-02',
    '2025-11-01',
    240,
    'ACTIVA'
);

-- -----------------------------------------------------------------------
-- 4. Seguimientos de prueba
--    Estados actuales del sistema: PENDIENTE, VALIDADO, COMPLETADO.
--    Se usan para mostrar el progreso real en el Dashboard del alumno.
-- -----------------------------------------------------------------------
INSERT INTO seguimientos (practica_id, fecha_registro, horas_realizadas,
                           descripcion, estado)
VALUES
    -- Parte validado por tutor centro (cuenta para el progreso)
    (
        (SELECT id FROM practicas WHERE codigo = 'FCT-2025-001'),
        '2025-04-07',
        8,
        'Primera semana de prácticas. Configuración del entorno de desarrollo y revisión de documentación.',
        'COMPLETADO'
    ),
    -- Parte validado por tutor empresa, pendiente de visto bueno del centro
    (
        (SELECT id FROM practicas WHERE codigo = 'FCT-2025-001'),
        '2025-04-14',
        8,
        'Segunda semana. Implementación del módulo de autenticación con JWT.',
        'VALIDADO'
    ),
    -- Parte recién registrado por el alumno, esperando firma del tutor de empresa
    (
        (SELECT id FROM practicas WHERE codigo = 'FCT-2025-001'),
        '2025-04-21',
        8,
        'Tercera semana. Desarrollo de pantallas Flutter para el dashboard y login.',
        'PENDIENTE'
    );

-- -----------------------------------------------------------------------
-- 5. Incidencia abierta vinculada a la práctica
-- -----------------------------------------------------------------------
INSERT INTO incidencias (practica_id, creada_por, tipo, descripcion, estado)
VALUES (
    (SELECT id FROM practicas WHERE codigo = 'FCT-2025-001'),
    (SELECT id FROM usuarios WHERE email = 'alumno@nexus.edu'),
    'ACCESO',
    'El alumno no tiene acceso al repositorio Git de la empresa. Solicita que se le añada con permisos de lectura/escritura.',
    'ABIERTA'
);
