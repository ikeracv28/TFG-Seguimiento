package com.tfg.api.controllers;

import com.tfg.api.models.dto.AusenciaRequest;
import com.tfg.api.models.dto.AusenciaResponse;
import com.tfg.api.services.AusenciaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import org.springframework.http.HttpHeaders;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/v1/ausencias")
@RequiredArgsConstructor
public class AusenciaController {

    private final AusenciaService ausenciaService;

    /** Alumno registra una ausencia en su práctica activa. */
    @PostMapping
    @PreAuthorize("hasRole('ALUMNO')")
    public ResponseEntity<AusenciaResponse> registrar(@Valid @RequestBody AusenciaRequest request) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ausenciaService.registrar(request, email));
    }

    /** Lista ausencias de una práctica (admin, tutores y el propio alumno). */
    @GetMapping("/practica/{practicaId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<List<AusenciaResponse>> listarPorPractica(@PathVariable Long practicaId) {
        return ResponseEntity.ok(ausenciaService.listarPorPractica(practicaId));
    }

    /** Detalle de una ausencia concreta. */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<AusenciaResponse> obtenerPorId(@PathVariable Long id) {
        return ResponseEntity.ok(ausenciaService.obtenerPorId(id));
    }

    /** Tutor empresa revisa la ausencia: JUSTIFICADA o INJUSTIFICADA + comentario opcional. */
    @PatchMapping("/{id}/revisar")
    @PreAuthorize("hasRole('TUTOR_EMPRESA')")
    public ResponseEntity<AusenciaResponse> revisar(
            @PathVariable Long id,
            @RequestParam String nuevoTipo,
            @RequestParam(required = false) String comentario) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(ausenciaService.revisar(id, nuevoTipo, comentario, email));
    }

    /** Descarga el fichero justificante adjunto (todos los roles con acceso). */
    @GetMapping("/{id}/justificante")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<byte[]> descargarJustificante(@PathVariable Long id) {
        AusenciaService.JustificanteDto dto = ausenciaService.descargarJustificante(id);
        // A03: sanitizar el nombre para evitar header injection
        String nombreSeguro = dto.nombreFichero() == null ? "justificante"
                : dto.nombreFichero().replaceAll("[\\r\\n\"\\\\]", "_");
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(dto.mimeType()))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "inline; filename=\"" + nombreSeguro + "\"")
                .body(dto.datos());
    }

    /** Alumno adjunta fichero justificante (PDF / JPG / PNG, máx 5 MB). */
    @PatchMapping(value = "/{id}/justificante", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('ALUMNO')")
    public ResponseEntity<AusenciaResponse> adjuntarJustificante(
            @PathVariable Long id,
            @RequestParam("fichero") MultipartFile fichero) throws IOException {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(ausenciaService.adjuntarJustificante(id, fichero, email));
    }

    /** Alumno elimina una ausencia todavía no revisada. */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ALUMNO')")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        ausenciaService.eliminar(id, email);
        return ResponseEntity.noContent().build();
    }
}
