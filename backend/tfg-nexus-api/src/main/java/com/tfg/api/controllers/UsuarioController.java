package com.tfg.api.controllers;

import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.services.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<UsuarioResponse> getMe() {
        return ResponseEntity.ok(usuarioService.getMe());
    }

    @PostMapping(value = "/me/foto", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> uploadFoto(@RequestParam("file") MultipartFile file) {
        usuarioService.uploadFoto(file);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/foto")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<byte[]> getFoto(@PathVariable Long id) {
        byte[] foto = usuarioService.getFoto(id);
        String contentType = usuarioService.getFotoContentType(id);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .body(foto);
    }
}
