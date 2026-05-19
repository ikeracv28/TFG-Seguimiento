package com.tfg.api.models.dto;

import jakarta.validation.constraints.*;
import java.time.LocalDate;

public record SeguimientoRequest(
    @NotNull(message = "El ID de la práctica es obligatorio")
    Long practicaId,

    @NotNull(message = "La fecha de registro es obligatoria")
    @PastOrPresent(message = "La fecha no puede ser futura")
    LocalDate fechaRegistro,

    @NotNull(message = "Las horas realizadas son obligatorias")
    @DecimalMin(value = "0.5", message = "Debe registrar al menos 0.5 horas")
    @DecimalMax(value = "50.0", message = "No se pueden registrar más de 50 horas")
    Double horasRealizadas,

    @NotBlank(message = "La descripción es obligatoria")
    @Size(min = 10, max = 1000, message = "La descripción debe tener entre 10 y 1000 caracteres")
    String descripcion,

    // Opcional: DIARIO (defecto) o SEMANAL
    String tipo
) {}
