package com.tfg.api.services;

import com.tfg.api.models.dto.UsuarioResponse;

/**
 * Interfaz que establece los métodos para la gestión de la información relativa a los usuarios.
 */
public interface UsuarioService {
    
    /**
     * Recupera la información del perfil del usuario que ha iniciado sesión actualmente.
     */
    UsuarioResponse getMe();
}
