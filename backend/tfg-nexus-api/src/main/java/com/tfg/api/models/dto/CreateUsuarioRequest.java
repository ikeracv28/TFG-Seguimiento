package com.tfg.api.models.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * DTO para que el administrador cree usuarios con un rol explícito.
 * A diferencia de RegisterRequest, aquí el rol lo elige el admin.
 */
public record CreateUsuarioRequest(

    @NotBlank(message = "El DNI es obligatorio")
    String dni,

    @NotBlank(message = "El nombre es obligatorio")
    String nombre,

    @NotBlank(message = "Los apellidos son obligatorios")
    String apellidos,

    @NotBlank(message = "El email es obligatorio")
    @Email(message = "El formato del email no es válido")
    String email,

    @NotBlank(message = "La contraseña es obligatoria")
    @Size(min = 8, message = "La contraseña debe tener al menos 8 caracteres")
    String password,

    @NotBlank(message = "El rol es obligatorio")
    String rolNombre
) {}
