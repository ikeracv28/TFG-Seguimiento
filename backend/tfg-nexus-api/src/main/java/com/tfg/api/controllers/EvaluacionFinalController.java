package com.tfg.api.controllers;

import com.tfg.api.models.dto.EvaluacionFinalRequest;
import com.tfg.api.models.dto.EvaluacionFinalResponse;
import com.tfg.api.services.EvaluacionFinalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/evaluaciones")
@RequiredArgsConstructor
public class EvaluacionFinalController {

    private final EvaluacionFinalService evaluacionService;

    // Solo el tutor de empresa puede evaluar a su alumno
    @PostMapping("/practica/{practicaId}")
    @PreAuthorize("hasRole('TUTOR_EMPRESA')")
    public ResponseEntity<EvaluacionFinalResponse> evaluar(
            @PathVariable Long practicaId,
            @Valid @RequestBody EvaluacionFinalRequest request) {
        return ResponseEntity.ok(evaluacionService.evaluar(practicaId, request));
    }

    // Todos los participantes y admin pueden consultar la evaluación
    @GetMapping("/practica/{practicaId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<EvaluacionFinalResponse> obtener(@PathVariable Long practicaId) {
        return evaluacionService.obtenerPorPractica(practicaId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.noContent().build());
    }
}
