package com.tfg.api.controllers;

import com.tfg.api.models.dto.PlanificarTutoriasRequest;
import com.tfg.api.models.dto.TutoriaResponse;
import com.tfg.api.services.TutoriaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/tutorias")
@RequiredArgsConstructor
public class TutoriaController {

    private final TutoriaService tutoriaService;

    @PostMapping("/planificar")
    @PreAuthorize("hasRole('TUTOR_CENTRO')")
    public ResponseEntity<List<TutoriaResponse>> planificar(
            @Valid @RequestBody PlanificarTutoriasRequest request,
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(tutoriaService.planificar(request, user.getUsername()));
    }

    @GetMapping("/mis-sesiones")
    @PreAuthorize("hasRole('TUTOR_CENTRO')")
    public ResponseEntity<List<TutoriaResponse>> misSesiones(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(tutoriaService.getMisSesiones(user.getUsername()));
    }

    @GetMapping("/mi-proxima")
    @PreAuthorize("hasRole('ALUMNO')")
    public ResponseEntity<TutoriaResponse> miProxima(
            @AuthenticationPrincipal UserDetails user) {
        TutoriaResponse r = tutoriaService.getProximaTutoriaAlumno(user.getUsername());
        return r != null ? ResponseEntity.ok(r) : ResponseEntity.noContent().build();
    }

    @PostMapping("/notificar")
    @PreAuthorize("hasRole('TUTOR_CENTRO')")
    public ResponseEntity<Map<String, Integer>> notificar(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha,
            @AuthenticationPrincipal UserDetails user) {
        int enviados = tutoriaService.enviarNotificaciones(fecha, user.getUsername());
        return ResponseEntity.ok(Map.of("enviados", enviados));
    }

    @DeleteMapping("/sesion")
    @PreAuthorize("hasRole('TUTOR_CENTRO')")
    public ResponseEntity<Void> eliminarSesion(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha,
            @AuthenticationPrincipal UserDetails user) {
        tutoriaService.eliminarSesion(fecha, user.getUsername());
        return ResponseEntity.noContent().build();
    }
}
