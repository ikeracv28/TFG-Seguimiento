package com.tfg.api.services;

import com.tfg.api.models.dto.IncidenciaRequest;
import com.tfg.api.models.dto.IncidenciaResponse;

import java.util.List;

public interface IncidenciaService {

    IncidenciaResponse crear(IncidenciaRequest request, String emailUsuario);

    List<IncidenciaResponse> listarPorPractica(Long practicaId);

    IncidenciaResponse obtenerPorId(Long id);

    IncidenciaResponse actualizarEstado(Long id, String nuevoEstado, String emailTutor);
}
