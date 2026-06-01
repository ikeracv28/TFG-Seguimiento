package com.tfg.api.services;

import com.tfg.api.models.dto.AuditLogResponse;
import com.tfg.api.models.entity.AuditLog;
import com.tfg.api.models.repository.AuditLogRepository;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository repo;

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
        final String moduloFiltro = (modulo == null || modulo.isBlank()) ? null : modulo.toUpperCase();
        final String emailFiltro  = (email  == null || email.isBlank())  ? null : email.trim().toLowerCase();
        final String accionFiltro = (accion == null || accion.isBlank()) ? null : accion.trim().toLowerCase();
        final LocalDateTime desde = fechaDesde != null ? fechaDesde.atStartOfDay() : null;
        final LocalDateTime hasta = fechaHasta != null ? fechaHasta.plusDays(1).atStartOfDay() : null;

        Specification<AuditLog> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (moduloFiltro != null) {
                predicates.add(cb.equal(root.get("modulo"), moduloFiltro));
            }
            if (emailFiltro != null) {
                predicates.add(cb.like(cb.lower(root.get("usuarioEmail")), "%" + emailFiltro + "%"));
            }
            if (accionFiltro != null) {
                predicates.add(cb.like(cb.lower(root.get("accion")), "%" + accionFiltro + "%"));
            }
            if (desde != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("fecha"), desde));
            }
            if (hasta != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("fecha"), hasta));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Pageable sortedPage = PageRequest.of(
                pageable.getPageNumber(),
                pageable.getPageSize(),
                Sort.by(Sort.Direction.DESC, "fecha"));

        return repo.findAll(spec, sortedPage).map(this::toResponse);
    }

    private AuditLogResponse toResponse(AuditLog l) {
        return new AuditLogResponse(
                l.getId(), l.getFecha(), l.getUsuarioEmail(),
                l.getModulo(), l.getAccion(), l.getEntidadId(), l.getDescripcion());
    }
}
