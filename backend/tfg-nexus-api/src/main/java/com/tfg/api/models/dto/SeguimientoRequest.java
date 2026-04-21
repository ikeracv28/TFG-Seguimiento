package com.tfg.api.models.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

/**
 * DTO para la creación o actualización de un registro de seguimiento diario.
 * Incluye validaciones básicas para asegurar la integridad de los datos recibidos.
 */
public record SeguimientoRequest(
    @NotNull(message = "El ID de la práctica es obligatorio")
    Long practicaId,

    @NotNull(message = "La fecha de registro es obligatoria")
    LocalDate fechaRegistro,

    @NotNull(message = "Las horas realizadas son obligatorias")
    @Min(value = 1, message = "Debe registrar al menos 1 hora")
    Integer horasRealizadas,

    String descripcion
) {}
