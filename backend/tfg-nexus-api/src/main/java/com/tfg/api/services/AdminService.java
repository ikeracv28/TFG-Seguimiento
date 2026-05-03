package com.tfg.api.services;

import com.tfg.api.models.dto.CreateUsuarioRequest;
import com.tfg.api.models.dto.UpdateUsuarioRequest;
import com.tfg.api.models.dto.UsuarioResponse;

import java.util.List;

public interface AdminService {
    UsuarioResponse crearUsuario(CreateUsuarioRequest request);
    List<UsuarioResponse> listarUsuarios();
    UsuarioResponse toggleActivo(Long id);
    UsuarioResponse editarUsuario(Long id, UpdateUsuarioRequest request);
}
