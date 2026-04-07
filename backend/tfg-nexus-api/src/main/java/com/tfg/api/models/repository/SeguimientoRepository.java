package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Seguimiento;
import com.tfg.api.models.entity.Practica;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

/**
 * Repositorio para la gestión de persistencia de la entidad Seguimiento.
 */
@Repository
public interface SeguimientoRepository extends JpaRepository<Seguimiento, Long> {

    /**
     * Lista los seguimientos de una práctica ordenados por fecha descendente.
     */
    List<Seguimiento> findByPracticaOrderByFechaRegistroDesc(Practica practica);

    /**
     * Filtra los seguimientos de una práctica por su estado.
     */
    List<Seguimiento> findByPracticaAndEstado(Practica practica, String estado);

    /**
     * Lista todos los seguimientos del sistema filtrados por su estado.
     */
    List<Seguimiento> findByEstado(String estado);
}
