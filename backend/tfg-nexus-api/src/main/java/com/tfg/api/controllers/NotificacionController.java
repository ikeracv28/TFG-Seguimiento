package com.tfg.api.controllers;

import com.tfg.api.models.dto.NotificacionResponse;
import com.tfg.api.services.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/notificaciones")
@RequiredArgsConstructor
public class NotificacionController {

    private final NotificacionService notificacionService;

    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<NotificacionResponse>> listar() {
        return ResponseEntity.ok(notificacionService.listarParaUsuario());
    }

    @GetMapping("/me/no-leidas")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Long>> contarNoLeidas() {
        return ResponseEntity.ok(Map.of("count", notificacionService.contarNoLeidas()));
    }

    @PatchMapping("/{id}/leer")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> marcarLeida(@PathVariable Long id) {
        notificacionService.marcarLeida(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/me/leer-todas")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> marcarTodasLeidas() {
        notificacionService.marcarTodasLeidas();
        return ResponseEntity.noContent().build();
    }
}
