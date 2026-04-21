package com.tfg.api.controllers;

import com.tfg.api.models.dto.EmpresaResponse;
import com.tfg.api.services.EmpresaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

/**
 * Controlador para la gestión de empresas colaboradoras.
 */
@RestController
@RequestMapping("/api/v1/empresas")
@RequiredArgsConstructor
public class EmpresaController {

    private final EmpresaService empresaService;

    /**
     * Devuelve el listado de todas las empresas registradas.
     */
    @GetMapping
    public ResponseEntity<List<EmpresaResponse>> getAll() {
        return ResponseEntity.ok(empresaService.findAll());
    }
}
