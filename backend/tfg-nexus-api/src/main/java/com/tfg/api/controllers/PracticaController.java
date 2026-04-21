package com.tfg.api.controllers;

import com.tfg.api.models.dto.PracticaRequest;
import com.tfg.api.models.dto.PracticaResponse;
import com.tfg.api.services.PracticaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST para la gestión de Prácticas Académicas.
 * Protegido mediante seguridad basada en roles (Hito 2).
 */
@RestController
@RequestMapping("/api/v1/practicas")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class PracticaController {

    private final PracticaService practicaService;

    /**
     * Obtiene el listado completo de prácticas.
     * Acceso: ADMIN y TUTORES.
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA')")
    public ResponseEntity<Page<PracticaResponse>> listarTodas(@PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(practicaService.listarTodas(pageable));
    }

    /**
     * Devuelve la práctica ACTIVA del alumno autenticado.
     * El alumno no necesita conocer su propio ID; el servicio lo obtiene del JWT.
     * Acceso: Solo ALUMNO.
     */
    @GetMapping("/me")
    @PreAuthorize("hasRole('ALUMNO')")
    public ResponseEntity<PracticaResponse> obtenerMiPracticaActiva() {
        return ResponseEntity.ok(practicaService.obtenerPracticaActivaDelAlumno());
    }

    /**
     * Obtiene los detalles de una práctica por su ID.
     * Acceso: Cualquier usuario autenticado (la lógica de servicio podría filtrar más adelante).
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<PracticaResponse> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(practicaService.obtenerPorId(id));
    }

    /**
     * Obtiene las prácticas de un alumno específico.
     * Acceso: ADMIN, TUTORES y el propio ALUMNO.
     */
    @GetMapping("/alumno/{alumnoId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA') or #alumnoId == authentication.principal.id")
    public ResponseEntity<List<PracticaResponse>> listarPorAlumno(@PathVariable Long alumnoId) {
        return ResponseEntity.ok(practicaService.listarPorAlumno(alumnoId));
    }

    /**
     * Crea una nueva práctica académica.
     * Acceso: Únicamente ADMINISTRADORES.
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PracticaResponse> crear(@Valid @RequestBody PracticaRequest request) {
        return new ResponseEntity<>(practicaService.crear(request), HttpStatus.CREATED);
    }

    /**
     * Actualiza los datos de una práctica.
     * Acceso: ADMIN y TUTOR_CENTRO.
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO')")
    public ResponseEntity<PracticaResponse> actualizar(@PathVariable Long id, @Valid @RequestBody PracticaRequest request) {
        return ResponseEntity.ok(practicaService.actualizar(id, request));
    }

    /**
     * Elimina una práctica (solo si está en estado BORRADOR).
     * Acceso: Únicamente ADMINISTRADORES.
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        practicaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Cambia el estado de una práctica.
     * Acceso: ADMIN y TUTORES.
     */
    @PatchMapping("/{id}/estado")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA')")
    public ResponseEntity<PracticaResponse> cambiarEstado(@PathVariable Long id, @RequestParam String nuevoEstado) {
        return ResponseEntity.ok(practicaService.cambiarEstado(id, nuevoEstado));
    }
}
