-- Declara la dependencia explícita de pgcrypto (usada en V6 y V7 para crypt/gen_salt).
-- IF NOT EXISTS garantiza idempotencia: no falla si ya está activa.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
