package com.tfg.api.services;

import com.tfg.api.models.dto.PlanificarTutoriasRequest;
import com.tfg.api.models.dto.TutoriaResponse;

import java.time.LocalDate;
import java.util.List;

public interface TutoriaService {
    List<TutoriaResponse> planificar(PlanificarTutoriasRequest request, String emailTutor);
    List<TutoriaResponse> getMisSesiones(String emailTutor);
    TutoriaResponse getProximaTutoriaAlumno(String emailAlumno);
    int enviarNotificaciones(LocalDate fecha, String emailTutor);
}
