package com.tfg.api.controllers;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.IncidenciaRequest;
import com.tfg.api.models.dto.IncidenciaResponse;
import com.tfg.api.models.entity.Incidencia;
import com.tfg.api.models.repository.IncidenciaRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST para la consulta de incidencias.
 * En el Hito 3 se ampliará con creación, actualización y flujo de resolución.
 */
@RestController
@RequestMapping("/api/v1/incidencias")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class IncidenciaController {

    private final IncidenciaRepository incidenciaRepository;
    private final UsuarioRepository usuarioRepository;
    private final PracticaRepository practicaRepository;

    /**
     * Reporta una nueva incidencia vinculada a la práctica activa del usuario autenticado.
     * Acceso: Alumno, tutores del centro y de empresa.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('ALUMNO', 'TUTOR_CENTRO', 'TUTOR_EMPRESA')")
    public ResponseEntity<IncidenciaResponse> crear(@Valid @RequestBody IncidenciaRequest request) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        var usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
        var practica = practicaRepository.findFirstByAlumnoIdAndEstado(usuario.getId(), "ACTIVA")
                .orElseThrow(() -> new BusinessRuleException("No tienes una práctica activa"));

        var incidencia = Incidencia.builder()
                .practica(practica)
                .creadaPor(usuario)
                .tipo(request.tipo())
                .descripcion(request.descripcion())
                .estado("ABIERTA")
                .build();

        var guardada = incidenciaRepository.save(incidencia);
        return ResponseEntity.status(HttpStatus.CREATED).body(new IncidenciaResponse(
                guardada.getId(),
                guardada.getPractica().getId(),
                guardada.getCreadaPor().getId(),
                guardada.getCreadaPor().getNombre() + " " + guardada.getCreadaPor().getApellidos(),
                guardada.getTipo(),
                guardada.getDescripcion(),
                guardada.getEstado(),
                guardada.getFechaCreacion()
        ));
    }

    /**
     * Lista las incidencias de una práctica, ordenadas de más reciente a más antigua.
     * Acceso: Todos los roles participantes en la práctica.
     */
    @GetMapping("/practica/{practicaId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<List<IncidenciaResponse>> listarPorPractica(@PathVariable Long practicaId) {
        var incidencias = incidenciaRepository
                .findByPracticaIdOrderByFechaCreacionDesc(practicaId)
                .stream()
                .map(i -> new IncidenciaResponse(
                        i.getId(),
                        i.getPractica().getId(),
                        i.getCreadaPor().getId(),
                        i.getCreadaPor().getNombre() + " " + i.getCreadaPor().getApellidos(),
                        i.getTipo(),
                        i.getDescripcion(),
                        i.getEstado(),
                        i.getFechaCreacion()
                ))
                .toList();

        return ResponseEntity.ok(incidencias);
    }

    /**
     * Obtiene el detalle de una incidencia concreta.
     * Acceso: Cualquier usuario autenticado con acceso a la práctica.
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<IncidenciaResponse> obtenerPorId(@PathVariable Long id) {
        var i = incidenciaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Incidencia no encontrada"));

        return ResponseEntity.ok(new IncidenciaResponse(
                i.getId(),
                i.getPractica().getId(),
                i.getCreadaPor().getId(),
                i.getCreadaPor().getNombre() + " " + i.getCreadaPor().getApellidos(),
                i.getTipo(),
                i.getDescripcion(),
                i.getEstado(),
                i.getFechaCreacion()
        ));
    }
}
