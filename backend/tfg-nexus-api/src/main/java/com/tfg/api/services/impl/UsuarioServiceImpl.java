package com.tfg.api.services.impl;

import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.mapper.UsuarioMapper;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UsuarioServiceImpl implements UsuarioService {

    private static final long MAX_FOTO_BYTES = 5 * 1024 * 1024; // 5 MB
    private static final List<String> ALLOWED_TYPES = List.of("image/jpeg", "image/png", "image/webp");

    private final UsuarioRepository usuarioRepository;
    private final UsuarioMapper usuarioMapper;

    @Override
    public UsuarioResponse getMe() {
        return usuarioMapper.toResponse(getUsuarioAutenticado());
    }

    @Override
    public void uploadFoto(MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_TYPES.contains(contentType)) {
            throw new IllegalArgumentException("Tipo de archivo no permitido. Use JPEG, PNG o WebP.");
        }
        if (file.getSize() > MAX_FOTO_BYTES) {
            throw new IllegalArgumentException("La foto no puede superar 2 MB.");
        }

        Usuario usuario = getUsuarioAutenticado();
        try {
            usuario.setFotoPerfil(file.getBytes());
            usuario.setFotoContentType(contentType);
        } catch (IOException e) {
            throw new RuntimeException("Error al leer el archivo de imagen.", e);
        }
        usuarioRepository.save(usuario);
    }

    @Override
    public byte[] getFoto(Long usuarioId) {
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado: " + usuarioId));
        if (usuario.getFotoPerfil() == null) {
            throw new ResourceNotFoundException("Este usuario no tiene foto de perfil.");
        }
        return usuario.getFotoPerfil();
    }

    @Override
    public String getFotoContentType(Long usuarioId) {
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado: " + usuarioId));
        return usuario.getFotoContentType() != null ? usuario.getFotoContentType() : "image/jpeg";
    }

    private Usuario getUsuarioAutenticado() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado con email: " + email));
    }
}
