package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Ausencia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface AusenciaRepository extends JpaRepository<Ausencia, Long> {

    List<Ausencia> findByPracticaIdOrderByFechaDesc(Long practicaId);

    boolean existsByPracticaIdAndFecha(Long practicaId, LocalDate fecha);

    long countByPracticaIdAndTipo(Long practicaId, String tipo);
}
