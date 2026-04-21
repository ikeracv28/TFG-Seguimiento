package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Seguimiento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

/**
 * Repositorio para la gestión de Seguimientos (partes de horas).
 * Hereda funcionalidades estándar de JpaRepository.
 */
@Repository
public interface SeguimientoRepository extends JpaRepository<Seguimiento, Long> {

    /**
     * Recupera todos los seguimientos vinculados a una práctica específica.
     * @param practicaId Identificador único de la práctica.
     * @return Lista de registros ordenados por fecha de registro descendente.
     */
    List<Seguimiento> findByPracticaIdOrderByFechaRegistroDesc(Long practicaId);

    /**
     * Filtra los seguimientos de una práctica por su estado (PENDIENTE, VALIDADO, RECHAZADO).
     * @param practicaId Identificador de la práctica.
     * @param estado Estado del seguimiento.
     * @return Lista filtrada de registros.
     */
    List<Seguimiento> findByPracticaIdAndEstado(Long practicaId, String estado);
}
