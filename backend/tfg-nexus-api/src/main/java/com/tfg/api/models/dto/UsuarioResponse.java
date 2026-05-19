package com.tfg.api.models.dto;

import java.util.Set;

public record UsuarioResponse(
    Long id,
    String dni,
    String nombre,
    String apellidos,
    String email,
    Set<String> roles,
    String centroNombre,
    boolean activo,
    boolean tieneFoto
) {}
