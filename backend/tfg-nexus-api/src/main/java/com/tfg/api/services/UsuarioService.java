package com.tfg.api.services;

import com.tfg.api.models.dto.UsuarioResponse;

/**
 * Servicio para la gestión de datos de usuario.
 */
public interface UsuarioService {
    
    /**
     * Obtiene el perfil del usuario actualmente autenticado.
     */
    UsuarioResponse getMe();
}
