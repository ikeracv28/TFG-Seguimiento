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
    @Min(value = 1, message = "Debe registrar al menos 1 hora")
    @Max(value = 24, message = "No se pueden registrar más de 24 horas al día")
    Integer horasRealizadas,

    @NotBlank(message = "La descripción es obligatoria")
    @Size(min = 10, max = 1000, message = "La descripción debe tener entre 10 y 1000 caracteres")
    String descripcion
) {}
