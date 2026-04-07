package com.tfg.api.models.dto;

import java.util.Set;

/**
 * DTO para la respuesta de autenticación exitosa.
 */
public record AuthResponse(
    String token,
    String email,
    String nombre,
    Set<String> roles
) {}
