-- Alinea la tabla mensajes con el esquema que espera la entidad JPA.
-- La tabla fue creada manualmente antes de que existiera la migración V10,
-- con columna 'emisor_id' y columna extra 'leido' que no existen en la entidad.

ALTER TABLE mensajes RENAME COLUMN emisor_id TO remitente_id;
ALTER TABLE mensajes DROP COLUMN IF EXISTS leido;
