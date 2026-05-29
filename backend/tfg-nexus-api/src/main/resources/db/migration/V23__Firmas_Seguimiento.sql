-- Añade campos de firma electrónica manuscrita a los partes de seguimiento.
-- La imagen se almacena como base64 en TEXT (PNG del canvas de firma).
ALTER TABLE seguimientos
  ADD COLUMN firma_alumno_imagen TEXT,
  ADD COLUMN firma_alumno_nombre VARCHAR(200),
  ADD COLUMN firma_alumno_fecha TIMESTAMP,
  ADD COLUMN firma_tutor_empresa_imagen TEXT,
  ADD COLUMN firma_tutor_empresa_nombre VARCHAR(200),
  ADD COLUMN firma_tutor_empresa_fecha TIMESTAMP;
