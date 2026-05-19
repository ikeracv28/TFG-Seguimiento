-- Añade soporte para foto de perfil en los usuarios
ALTER TABLE usuarios
    ADD COLUMN foto_perfil    BYTEA,
    ADD COLUMN foto_content_type VARCHAR(50);
