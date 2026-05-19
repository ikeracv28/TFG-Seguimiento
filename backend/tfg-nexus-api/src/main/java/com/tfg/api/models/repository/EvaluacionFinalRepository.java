package com.tfg.api.models.repository;

import com.tfg.api.models.entity.EvaluacionFinal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface EvaluacionFinalRepository extends JpaRepository<EvaluacionFinal, Long> {

    @Query("SELECT e FROM EvaluacionFinal e JOIN FETCH e.practica JOIN FETCH e.tutorEmpresa WHERE e.practica.id = :practicaId")
    Optional<EvaluacionFinal> findByPracticaId(@Param("practicaId") Long practicaId);
}
