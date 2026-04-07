package com.tfg.api.services;

import com.tfg.api.models.dto.AuthResponse;
import com.tfg.api.models.dto.LoginRequest;
import com.tfg.api.models.dto.RegisterRequest;

/**
 * Interfaz que define los servicios de autenticación y registro de usuarios en el sistema.
 */
public interface AuthService {

    /**
     * Procesa el registro de un nuevo usuario y devuelve la respuesta con el token de acceso.
     */
    AuthResponse registrar(RegisterRequest request);

    /**
     * Realiza la validación de credenciales y genera el token JWT para el inicio de sesión.
     */
    AuthResponse login(LoginRequest request);
}
