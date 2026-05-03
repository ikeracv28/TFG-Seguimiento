-- V6: Actualizar contraseñas de usuarios de prueba a política OWASP (A02)
-- Política: 12+ caracteres, mayúscula, minúscula, número y símbolo.
-- Nuevas contraseñas: Admin@Nexus2026 / Tutor@Nexus2026 / Alumno@Nexus2026 / Empresa@Nexus2026
-- Hashes generados con BCrypt cost=10.

UPDATE usuarios SET password_hash = '$2a$10$OJSk411db2WX/4wm3kUYZe0tPVQKdSTgoPV9ijyvhmMq2DuPJeEYm'
WHERE email = 'admin@nexus.edu';

UPDATE usuarios SET password_hash = '$2a$10$tPOPK5qC0RMs5HtF/ezNm.nDFRJ54Gt8Lh0vx7f8jUXEV7xPKF8TO'
WHERE email = 'tutor@nexus.edu';

UPDATE usuarios SET password_hash = '$2a$10$nO9IdyCkILNebhvtLonQ3uvfJdZIWnRSwZ/Fmql29yIVPsIUfK9i.'
WHERE email = 'alumno@nexus.edu';

UPDATE usuarios SET password_hash = '$2a$10$coluRGpwNE/aDvxFUaMv5.AdNKOfhBDenvxh2Okrk284Gp5apSJmS'
WHERE email = 'tutorempresa@nexus.edu';

-- Eliminar usuarios temporales creados para generar los hashes (primero la tabla intermedia por FK)
DELETE FROM usuario_roles WHERE usuario_id IN (SELECT id FROM usuarios WHERE email LIKE 'tmp%');
DELETE FROM usuarios WHERE email LIKE 'tmp%';
