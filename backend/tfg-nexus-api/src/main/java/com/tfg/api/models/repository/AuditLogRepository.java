package com.tfg.api.models.repository;

import com.tfg.api.models.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    @Query("SELECT a FROM AuditLog a WHERE " +
            "(:modulo IS NULL OR a.modulo = :modulo) AND " +
            "(:email IS NULL OR LOWER(a.usuarioEmail) LIKE LOWER(CONCAT('%', :email, '%'))) AND " +
            "(:accion IS NULL OR LOWER(a.accion) LIKE LOWER(CONCAT('%', :accion, '%'))) AND " +
            "(:fechaDesde IS NULL OR a.fecha >= :fechaDesde) AND " +
            "(:fechaHasta IS NULL OR a.fecha <= :fechaHasta) " +
            "ORDER BY a.fecha DESC")
    Page<AuditLog> filtrar(
            @Param("modulo") String modulo,
            @Param("email") String email,
            @Param("accion") String accion,
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            Pageable pageable);
}
