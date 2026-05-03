package com.tfg.api.models.repository;

import com.tfg.api.models.entity.Mensaje;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MensajeRepository extends JpaRepository<Mensaje, Long> {
    List<Mensaje> findByPracticaIdOrderByFechaEnvioAsc(Long practicaId);
}
