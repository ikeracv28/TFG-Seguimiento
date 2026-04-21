package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Incidencia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositorio para la entidad Incidencia.
 */
@Repository
public interface IncidenciaRepository extends JpaRepository<Incidencia, Long> {

    /**
     * Lista todas las incidencias de una práctica ordenadas por fecha de creación descendente.
     */
    List<Incidencia> findByPracticaIdOrderByFechaCreacionDesc(Long practicaId);
}
