package com.tfg.api.services;

import com.tfg.api.models.dto.AuditLogResponse;
import com.tfg.api.models.entity.AuditLog;
import com.tfg.api.models.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository repo;

    /**
     * Registra una acción en el log de auditoría.
     * Usa REQUIRES_NEW para que el log se persista aunque la transacción
     * principal falle (el log de un intento fallido también es valioso).
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrar(String modulo, String accion, Long entidadId,
                          String descripcion, String usuarioEmail) {
        repo.save(AuditLog.builder()
                .modulo(modulo)
                .accion(accion)
                .entidadId(entidadId)
                .descripcion(descripcion)
                .usuarioEmail(usuarioEmail)
                .build());
    }

    @Transactional(readOnly = true)
    public Page<AuditLogResponse> listar(String modulo, String email, String accion,
                                          LocalDate fechaDesde, LocalDate fechaHasta,
                                          Pageable pageable) {
        String moduloFiltro = (modulo == null || modulo.isBlank()) ? null : modulo.toUpperCase();
        String emailFiltro  = (email  == null || email.isBlank())  ? null : email.trim();
        String accionFiltro = (accion == null || accion.isBlank()) ? null : accion.trim();
        LocalDateTime desde = fechaDesde != null ? fechaDesde.atStartOfDay() : null;
        LocalDateTime hasta = fechaHasta != null ? fechaHasta.plusDays(1).atStartOfDay() : null;
        return repo.filtrar(moduloFiltro, emailFiltro, accionFiltro, desde, hasta, pageable)
                   .map(this::toResponse);
    }

    private AuditLogResponse toResponse(AuditLog l) {
        return new AuditLogResponse(
                l.getId(), l.getFecha(), l.getUsuarioEmail(),
                l.getModulo(), l.getAccion(), l.getEntidadId(), l.getDescripcion());
    }
}
