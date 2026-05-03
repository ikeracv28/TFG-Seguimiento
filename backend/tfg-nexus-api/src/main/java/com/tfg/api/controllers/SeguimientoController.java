package com.tfg.api.controllers;

import com.tfg.api.models.dto.SeguimientoRequest;
import com.tfg.api.models.dto.SeguimientoResponse;
import com.tfg.api.services.SeguimientoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/seguimientos")
@RequiredArgsConstructor
public class SeguimientoController {

    private final SeguimientoService seguimientoService;

    @PostMapping
    @PreAuthorize("hasRole('ALUMNO')")
    public ResponseEntity<SeguimientoResponse> registrar(@Valid @RequestBody SeguimientoRequest request) {
        return new ResponseEntity<>(seguimientoService.registrar(request), HttpStatus.CREATED);
    }

    @GetMapping("/practica/{practicaId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<List<SeguimientoResponse>> listarPorPractica(@PathVariable Long practicaId) {
        return ResponseEntity.ok(seguimientoService.listarPorPractica(practicaId));
    }

    /**
     * Primera validación: solo el tutor de empresa puede actuar sobre partes en PENDIENTE_EMPRESA.
     * nuevoEstado: PENDIENTE_CENTRO (aprueba) o RECHAZADO (rechaza, motivo obligatorio).
     */
    @PatchMapping("/{id}/validar-empresa")
    @PreAuthorize("hasRole('TUTOR_EMPRESA')")
    public ResponseEntity<SeguimientoResponse> validarEmpresa(
            @PathVariable Long id,
            @RequestParam String nuevoEstado,
            @RequestParam(required = false) String motivo) {
        return ResponseEntity.ok(seguimientoService.validarEmpresa(id, nuevoEstado, motivo));
    }

    /**
     * Segunda validación: solo el tutor del centro puede actuar sobre partes en PENDIENTE_CENTRO.
     * Siempre marca el parte como COMPLETADO (las horas se suman al progreso).
     */
    @PatchMapping("/{id}/validar-centro")
    @PreAuthorize("hasRole('TUTOR_CENTRO')")
    public ResponseEntity<SeguimientoResponse> validarCentro(@PathVariable Long id) {
        return ResponseEntity.ok(seguimientoService.validarCentro(id));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ALUMNO')")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        seguimientoService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
