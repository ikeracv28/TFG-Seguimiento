package com.tfg.api.models.dto;

import jakarta.validation.constraints.*;
import java.time.LocalDate;

public record AusenciaRequest(

    @NotNull(message = "El ID de la práctica es obligatorio")
    Long practicaId,

    @NotNull(message = "La fecha de la ausencia es obligatoria")
    @PastOrPresent(message = "La fecha no puede ser futura")
    LocalDate fecha,

    @NotBlank(message = "El motivo es obligatorio")
    @Size(min = 10, max = 1000, message = "El motivo debe tener entre 10 y 1000 caracteres")
    String motivo
) {}
