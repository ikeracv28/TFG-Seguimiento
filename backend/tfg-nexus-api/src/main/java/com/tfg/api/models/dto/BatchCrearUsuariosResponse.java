package com.tfg.api.models.dto;

import java.util.List;

public record BatchCrearUsuariosResponse(
    int creados,
    int errores,
    List<UsuarioResponse> usuariosCreados,
    List<ErrorDetalle> erroresDetalle
) {
    public record ErrorDetalle(String email, String motivo) {}
}
