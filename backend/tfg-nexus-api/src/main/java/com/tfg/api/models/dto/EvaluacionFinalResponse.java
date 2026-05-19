package com.tfg.api.models.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record EvaluacionFinalResponse(
    Long id,
    Long practicaId,
    String alumnoNombre,
    // Criterios (null si no se rellenaron)
    BigDecimal actitudPuntualidad,
    BigDecimal competenciaTecnica,
    BigDecimal iniciativaAutonomia,
    BigDecimal trabajoEquipo,
    BigDecimal cumplimientoTareas,
    // Nota global
    BigDecimal notaGlobal,
    String comentario,
    Long tutorEmpresaId,
    String tutorEmpresaNombre,
    LocalDateTime fechaEvaluacion
) {}
