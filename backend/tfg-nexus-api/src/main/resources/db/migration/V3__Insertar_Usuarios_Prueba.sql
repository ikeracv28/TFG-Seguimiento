-- V3__Insertar_Usuarios_Prueba.sql
-- Habilitar extensión para cifrado nativo en PostgreSQL
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Insertar usuarios de prueba utilizando la extensión para generar BCrypt (compatible con Spring Security)
INSERT INTO usuarios (dni, nombre, apellidos, email, password_hash, centro_id, activo) VALUES 
('11111111A', 'Administrador', 'Sistema', 'admin@nexus.edu', crypt('admin123', gen_salt('bf')), (SELECT id FROM centros LIMIT 1), true),
('22222222B', 'Profesor', 'Tutor', 'tutor@nexus.edu', crypt('123456', gen_salt('bf')), (SELECT id FROM centros LIMIT 1), true),
('33333333C', 'Estudiante', 'Pruebas', 'alumno@nexus.edu', crypt('123456', gen_salt('bf')), (SELECT id FROM centros LIMIT 1), true);

-- Asignar roles a los usuarios creados
-- Según V2: 1=ROLE_ALUMNO, 2=ROLE_TUTOR_CENTRO, 3=ROLE_TUTOR_EMPRESA, 4=ROLE_ADMIN
INSERT INTO usuario_roles (usuario_id, rol_id) VALUES 
((SELECT id FROM usuarios WHERE dni = '11111111A'), 4),
((SELECT id FROM usuarios WHERE dni = '22222222B'), 2),
((SELECT id FROM usuarios WHERE dni = '33333333C'), 1);
