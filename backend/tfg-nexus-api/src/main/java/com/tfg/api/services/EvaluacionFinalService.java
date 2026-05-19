package com.tfg.api.services;

import com.tfg.api.models.dto.EvaluacionFinalRequest;
import com.tfg.api.models.dto.EvaluacionFinalResponse;

import java.util.Optional;

public interface EvaluacionFinalService {

    EvaluacionFinalResponse evaluar(Long practicaId, EvaluacionFinalRequest request);

    Optional<EvaluacionFinalResponse> obtenerPorPractica(Long practicaId);
}
