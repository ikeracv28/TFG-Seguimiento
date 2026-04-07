-- V2__Insertar_Roles.sql
-- Insertamos los roles fundamentales para que el sistema funcione desde el primer día.

INSERT INTO roles (nombre, descripcion) VALUES 
('ROLE_ALUMNO', 'Usuario estudiante que realiza las prácticas y sube seguimientos'),
('ROLE_TUTOR_CENTRO', 'Profesor del instituto que supervisa y valida las prácticas'),
('ROLE_TUTOR_EMPRESA', 'Supervisor de la empresa que guía al alumno en el entorno laboral'),
('ROLE_ADMIN', 'Administrador con control total sobre centros, usuarios y roles');

-- También podemos insertar un Centro de prueba para facilitar los primeros registros
INSERT INTO centros (nombre, direccion, telefono, email) VALUES 
('IES Tecnológico Nexus', 'Calle de la Innovación, 12, Madrid', '912345678', 'contacto@iesnexus.edu');
