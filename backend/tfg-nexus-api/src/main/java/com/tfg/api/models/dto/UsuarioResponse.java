package com.tfg.api.models.dto;

import java.util.Set;

/**
 * Record que representa el perfil público de un usuario.
 * Se utiliza para devolver la información tras la autenticación o en el endpoint /me.
 * 
 * @param id Identificador único.
 * @param dni Documento nacional de identidad.
 * @param nombre Nombre de pila.
 * @param apellidos Apellidos completos.
 * @param email Correo electrónico.
 * @param roles Conjunto de nombres de roles asignados.
 * @param centroNombre Nombre del centro educativo asociado (si existe).
 * @param activo Estado de la cuenta.
 */
public record UsuarioResponse(
    Long id,
    String dni,
    String nombre,
    String apellidos,
    String email,
    Set<String> roles,
    String centroNombre,
    boolean activo
) {}
