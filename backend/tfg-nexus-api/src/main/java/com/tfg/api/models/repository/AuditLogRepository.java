package com.tfg.api.models.repository;

import com.tfg.api.models.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {
    Page<AuditLog> findByModuloOrderByFechaDesc(String modulo, Pageable pageable);
    Page<AuditLog> findAllByOrderByFechaDesc(Pageable pageable);
}
