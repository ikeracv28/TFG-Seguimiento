package com.tfg.api.controllers;

import com.tfg.api.models.dto.IncidenciaRequest;
import com.tfg.api.models.dto.IncidenciaResponse;
import com.tfg.api.services.IncidenciaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/incidencias")
@RequiredArgsConstructor
public class IncidenciaController {

    private final IncidenciaService incidenciaService;

    @PostMapping
    @PreAuthorize("hasAnyRole('ALUMNO', 'TUTOR_CENTRO', 'TUTOR_EMPRESA')")
    public ResponseEntity<IncidenciaResponse> crear(@Valid @RequestBody IncidenciaRequest request) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(incidenciaService.crear(request, email));
    }

    @GetMapping("/practica/{practicaId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<List<IncidenciaResponse>> listarPorPractica(@PathVariable Long practicaId) {
        return ResponseEntity.ok(incidenciaService.listarPorPractica(practicaId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<IncidenciaResponse> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(incidenciaService.obtenerPorId(id));
    }

    /**
     * Actualiza el estado de una incidencia (ABIERTA → EN_PROCESO → RESUELTA → CERRADA).
     * Solo el tutor del centro puede gestionar la resolución.
     */
    @PatchMapping("/{id}/estado")
    @PreAuthorize("hasRole('TUTOR_CENTRO')")
    public ResponseEntity<IncidenciaResponse> actualizarEstado(
            @PathVariable Long id,
            @RequestParam String nuevoEstado) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(incidenciaService.actualizarEstado(id, nuevoEstado, email));
    }
}
