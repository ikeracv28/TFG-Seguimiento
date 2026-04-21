package com.tfg.api.models.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Record que representa la solicitud de registro de un nuevo usuario.
 * 
 * Uso de Java 21 Records:
 * Los Records son ideales para DTOs porque son inmutables por naturaleza, 
 * ligeros y reducen el código boilerplate (sin necesidad de getters ni constructores).
 * 
 * Anotaciones de validación (Bean Validation):
 * - @NotBlank: Asegura que el campo no esté vacío ni solo con espacios.
 * - @Email: Valida que el formato del correo sea correcto.
 * - @Size: Establece límites de longitud (ej: mínimo 8 caracteres para la contraseña).
 */
public record RegisterRequest(
    
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
    String password
) {}
