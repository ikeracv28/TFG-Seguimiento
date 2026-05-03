package com.tfg.api.controllers;

import com.tfg.api.models.dto.AuditLogResponse;
import com.tfg.api.models.dto.CreateUsuarioRequest;
import com.tfg.api.models.dto.UpdateUsuarioRequest;
import com.tfg.api.models.dto.UsuarioResponse;
import com.tfg.api.services.AdminService;
import com.tfg.api.services.AuditService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final AuditService auditService;

    @GetMapping("/usuarios")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<UsuarioResponse>> listarUsuarios() {
        return ResponseEntity.ok(adminService.listarUsuarios());
    }

    @PostMapping("/usuarios")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UsuarioResponse> crearUsuario(@Valid @RequestBody CreateUsuarioRequest request) {
        return new ResponseEntity<>(adminService.crearUsuario(request), HttpStatus.CREATED);
    }

    @PatchMapping("/usuarios/{id}/toggle-activo")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UsuarioResponse> toggleActivo(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.toggleActivo(id));
    }

    @PutMapping("/usuarios/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UsuarioResponse> editarUsuario(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUsuarioRequest request) {
        return ResponseEntity.ok(adminService.editarUsuario(id, request));
    }

    @GetMapping("/audit-logs")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<AuditLogResponse>> listarAuditLogs(
            @RequestParam(required = false) String modulo,
            @PageableDefault(size = 50, sort = "fecha") Pageable pageable) {
        return ResponseEntity.ok(auditService.listar(modulo, pageable));
    }
}
