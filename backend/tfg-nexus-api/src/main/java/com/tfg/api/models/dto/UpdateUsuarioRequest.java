package com.tfg.api.models.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record UpdateUsuarioRequest(

    @NotBlank(message = "El DNI es obligatorio")
    String dni,

    @NotBlank(message = "El nombre es obligatorio")
    String nombre,

    @NotBlank(message = "Los apellidos son obligatorios")
    String apellidos,

    @NotBlank(message = "El email es obligatorio")
    @Email(message = "El formato del email no es válido")
    String email,

    @NotBlank(message = "El rol es obligatorio")
    String rolNombre
) {}
