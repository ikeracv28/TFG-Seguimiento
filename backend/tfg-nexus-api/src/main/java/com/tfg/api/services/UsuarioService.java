package com.tfg.api.services;

import com.tfg.api.models.dto.UsuarioResponse;
import org.springframework.web.multipart.MultipartFile;

public interface UsuarioService {
    UsuarioResponse getMe();
    void uploadFoto(MultipartFile file);
    byte[] getFoto(Long usuarioId);
    String getFotoContentType(Long usuarioId);
}
