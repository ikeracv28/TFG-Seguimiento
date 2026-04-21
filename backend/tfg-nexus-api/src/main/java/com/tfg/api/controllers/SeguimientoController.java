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

/**
 * Controlador REST para la gestión de Seguimientos Diarios.
 * Protegido mediante seguridad basada en roles.
 */
@RestController
@RequestMapping("/api/v1/seguimientos")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SeguimientoController {

    private final SeguimientoService seguimientoService;

    /**
     * Registra un nuevo parte de seguimiento.
     * Acceso: Únicamente ALUMNOS.
     */
    @PostMapping
    @PreAuthorize("hasRole('ALUMNO')")
    public ResponseEntity<SeguimientoResponse> registrar(@Valid @RequestBody SeguimientoRequest request) {
        return new ResponseEntity<>(seguimientoService.registrar(request), HttpStatus.CREATED);
    }

    /**
     * Lista el historial de seguimientos de una práctica.
     * Acceso: Todos los roles involucrados en el convenio.
     */
    @GetMapping("/practica/{practicaId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<List<SeguimientoResponse>> listarPorPractica(@PathVariable Long practicaId) {
        return ResponseEntity.ok(seguimientoService.listarPorPractica(practicaId));
    }

    /**
     * Valida o rechaza un registro de seguimiento.
     * Acceso: TUTORES del centro o de la empresa.
     */
    @PatchMapping("/{id}/validar")
    @PreAuthorize("hasAnyRole('TUTOR_CENTRO', 'TUTOR_EMPRESA')")
    public ResponseEntity<SeguimientoResponse> validar(
            @PathVariable Long id,
            @RequestParam String nuevoEstado,
            @RequestParam(required = false) String comentario) {
        return ResponseEntity.ok(seguimientoService.validar(id, nuevoEstado, comentario));
    }

    /**
     * Elimina un registro de seguimiento.
     * Acceso: ALUMNOS (la lógica de servicio limita el borrado a estados PENDIENTE).
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ALUMNO')")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        seguimientoService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
