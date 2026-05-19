-- Separa los mensajes de chat en dos canales:
-- ALUMNO  → alumno ↔ tutor centro
-- TUTORES → tutor empresa ↔ tutor centro
ALTER TABLE mensajes ADD COLUMN canal VARCHAR(20) NOT NULL DEFAULT 'ALUMNO';
CREATE INDEX idx_mensajes_practica_canal ON mensajes(practica_id, canal);
