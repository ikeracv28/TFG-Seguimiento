package com.tfg.api.models.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record EvaluacionFinalRequest(

    // Criterios opcionales 1–10
    @DecimalMin(value = "1.0") @DecimalMax(value = "10.0")
    BigDecimal actitudPuntualidad,

    @DecimalMin(value = "1.0") @DecimalMax(value = "10.0")
    BigDecimal competenciaTecnica,

    @DecimalMin(value = "1.0") @DecimalMax(value = "10.0")
    BigDecimal iniciativaAutonomia,

    @DecimalMin(value = "1.0") @DecimalMax(value = "10.0")
    BigDecimal trabajoEquipo,

    @DecimalMin(value = "1.0") @DecimalMax(value = "10.0")
    BigDecimal cumplimientoTareas,

    // Nota global obligatoria 0–10
    @NotNull(message = "La nota global es obligatoria")
    @DecimalMin(value = "0.00", message = "La nota mínima es 0")
    @DecimalMax(value = "10.00", message = "La nota máxima es 10")
    @Digits(integer = 2, fraction = 2)
    BigDecimal notaGlobal,

    @Size(max = 2000)
    String comentario
) {}
