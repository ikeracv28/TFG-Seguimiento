package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Tutoria;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface TutoriaRepository extends JpaRepository<Tutoria, Long> {
    List<Tutoria> findByTutorCentroIdOrderByFechaHoraAsc(Long tutorId);
    Optional<Tutoria> findFirstByAlumnoIdAndFechaHoraAfterOrderByFechaHoraAsc(Long alumnoId, LocalDateTime ahora);
    void deleteByTutorCentroIdAndFechaHoraBetween(Long tutorId, LocalDateTime desde, LocalDateTime hasta);
}
