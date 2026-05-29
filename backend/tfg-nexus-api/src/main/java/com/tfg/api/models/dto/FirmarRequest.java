package com.tfg.api.models.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record FirmarRequest(
    @NotBlank(message = "La imagen de firma es obligatoria")
    String imagenBase64,

    @NotBlank(message = "El rol firmante es obligatorio")
    @Pattern(regexp = "ALUMNO|TUTOR_EMPRESA", message = "El rol debe ser ALUMNO o TUTOR_EMPRESA")
    String rol
) {}
