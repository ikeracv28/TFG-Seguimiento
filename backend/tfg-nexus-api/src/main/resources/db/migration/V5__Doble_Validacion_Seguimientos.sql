-- V5__Doble_Validacion_Seguimientos.sql
-- Migra los estados de seguimientos al modelo de doble validación (empresa → centro).
-- Los registros existentes se reclasifican según su estado previo.

-- PENDIENTE  → alumno registró el parte, estaba esperando cualquier tutor
--              ahora espera específicamente al tutor de empresa (primer paso)
UPDATE seguimientos SET estado = 'PENDIENTE_EMPRESA' WHERE estado = 'PENDIENTE';

-- VALIDADO   → tutor de empresa ya lo aprobó, estaba esperando al tutor del centro
UPDATE seguimientos SET estado = 'PENDIENTE_CENTRO' WHERE estado = 'VALIDADO';

-- COMPLETADO y RECHAZADO se mantienen sin cambios.
