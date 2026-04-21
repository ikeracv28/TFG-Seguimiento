package com.tfg.api.models.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

/**
 * DTO para la creación o actualización de una Práctica.
 * Se usan IDs de las entidades relacionadas para simplificar la petición.
 */
public record PracticaRequest(
    @NotBlank(message = "El código es obligatorio")
    @Size(max = 50)
    String codigo,

    @NotNull(message = "El ID del alumno es obligatorio")
    Long alumnoId,

    @NotNull(message = "El ID del tutor del centro es obligatorio")
    Long tutorCentroId,

    @NotNull(message = "El ID del tutor de la empresa es obligatorio")
    Long tutorEmpresaId,

    @NotNull(message = "El ID de la empresa es obligatorio")
    Long empresaId,

    LocalDate fechaInicio,
    LocalDate fechaFin,
    Integer horasTotales,
    
    @Size(max = 20)
    String estado
) {}
