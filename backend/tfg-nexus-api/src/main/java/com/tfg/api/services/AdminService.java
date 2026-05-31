package com.tfg.api.services;

import com.tfg.api.models.dto.BatchCrearUsuariosRequest;
import com.tfg.api.models.dto.BatchCrearUsuariosResponse;
import com.tfg.api.models.dto.CreateUsuarioRequest;
import com.tfg.api.models.dto.UpdateUsuarioRequest;
import com.tfg.api.models.dto.UsuarioResponse;

import java.util.List;

public interface AdminService {
    UsuarioResponse crearUsuario(CreateUsuarioRequest request);
    BatchCrearUsuariosResponse crearUsuariosEnBatch(BatchCrearUsuariosRequest request);
    List<UsuarioResponse> listarUsuarios();
    UsuarioResponse toggleActivo(Long id);
    UsuarioResponse editarUsuario(Long id, UpdateUsuarioRequest request);
    void eliminarUsuario(Long id);
}
