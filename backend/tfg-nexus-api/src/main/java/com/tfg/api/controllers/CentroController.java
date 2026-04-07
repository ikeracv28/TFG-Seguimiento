package com.tfg.api.controllers;

import com.tfg.api.models.dto.CentroResponse;
import com.tfg.api.services.CentroService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

/**
 * Controlador para la gestión y consulta de los centros educativos del sistema.
 */
@RestController
@RequestMapping("/api/v1/centros")
@RequiredArgsConstructor
public class CentroController {

    private final CentroService centroService;

    // Recuperación del listado completo de centros educativos disponibles
    @GetMapping
    public ResponseEntity<List<CentroResponse>> getAll() {
        return ResponseEntity.ok(centroService.findAll());
    }
}
