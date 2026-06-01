package com.tfg.api.models.repository;

import com.tfg.api.models.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    @Query(value = "SELECT * FROM audit_logs WHERE " +
            "(:modulo IS NULL OR modulo = :modulo) AND " +
            "(:email IS NULL OR LOWER(usuario_email) LIKE LOWER(CONCAT('%', :email, '%'))) AND " +
            "(:accion IS NULL OR LOWER(accion) LIKE LOWER(CONCAT('%', :accion, '%'))) AND " +
            "(:fechaDesde IS NULL OR fecha >= :fechaDesde) AND " +
            "(:fechaHasta IS NULL OR fecha <= :fechaHasta) " +
            "ORDER BY fecha DESC",
           countQuery = "SELECT COUNT(*) FROM audit_logs WHERE " +
            "(:modulo IS NULL OR modulo = :modulo) AND " +
            "(:email IS NULL OR LOWER(usuario_email) LIKE LOWER(CONCAT('%', :email, '%'))) AND " +
            "(:accion IS NULL OR LOWER(accion) LIKE LOWER(CONCAT('%', :accion, '%'))) AND " +
            "(:fechaDesde IS NULL OR fecha >= :fechaDesde) AND " +
            "(:fechaHasta IS NULL OR fecha <= :fechaHasta)",
           nativeQuery = true)
    Page<AuditLog> filtrar(
            @Param("modulo") String modulo,
            @Param("email") String email,
            @Param("accion") String accion,
            @Param("fechaDesde") LocalDateTime fechaDesde,
            @Param("fechaHasta") LocalDateTime fechaHasta,
            Pageable pageable);
}
