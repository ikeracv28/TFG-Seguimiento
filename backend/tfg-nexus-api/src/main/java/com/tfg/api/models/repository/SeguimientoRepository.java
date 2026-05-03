package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Seguimiento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;

@Repository
public interface SeguimientoRepository extends JpaRepository<Seguimiento, Long> {

    List<Seguimiento> findByPracticaIdOrderByFechaRegistroDesc(Long practicaId);

    List<Seguimiento> findByPracticaIdAndEstado(Long practicaId, String estado);

    // Detecta si ya existe un parte pendiente en la misma semana ISO (lunes-domingo)
    boolean existsByPracticaIdAndEstadoAndFechaRegistroBetween(
            Long practicaId, String estado, LocalDate inicio, LocalDate fin);
}
