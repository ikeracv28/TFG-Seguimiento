package com.tfg.api.models.dto;

import java.util.Set;

/**
 * Respuesta enviada tras un login o registro exitoso.
 * Contiene el Token JWT necesario para las peticiones posteriores.
 * 
 * Además de la clave de acceso (token), devolvemos información 
 * útil para que el Frontend (Flutter Web/Móvil) pueda 
 * mostrar el nombre del usuario y gestionar los menús 
 * según sus roles sin tener que hacer otra petición inmediata.
 */
public record AuthResponse(
    Long id,
    String token,
    String email,
    String nombre,
    Set<String> roles
) {}
