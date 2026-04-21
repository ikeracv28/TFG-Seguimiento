package com.tfg.api.models.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * DTO para que el alumno reporte una nueva incidencia en su práctica activa.
 */
public record IncidenciaRequest(

    @NotBlank(message = "El tipo es obligatorio")
    String tipo,

    @NotBlank(message = "La descripcion es obligatoria")
    @Size(min = 10, max = 1000, message = "La descripcion debe tener entre 10 y 1000 caracteres")
    String descripcion
) {}
