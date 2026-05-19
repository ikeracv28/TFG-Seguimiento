package com.tfg.api.services.impl;

import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.EvaluacionFinalRequest;
import com.tfg.api.models.dto.EvaluacionFinalResponse;
import com.tfg.api.models.entity.EvaluacionFinal;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.EvaluacionFinalRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.AuditService;
import com.tfg.api.services.EvaluacionFinalService;
import com.tfg.api.services.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class EvaluacionFinalServiceImpl implements EvaluacionFinalService {

    private final EvaluacionFinalRepository evaluacionRepository;
    private final PracticaRepository practicaRepository;
    private final UsuarioRepository usuarioRepository;
    private final AuditService auditService;
    private final NotificacionService notificacionService;

    @Override
    @Transactional
    public EvaluacionFinalResponse evaluar(Long practicaId, EvaluacionFinalRequest request) {
        String emailTutor = SecurityContextHolder.getContext().getAuthentication().getName();

        Practica practica = practicaRepository.findById(practicaId)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        // A01: solo el tutor de empresa de esta práctica puede evaluar
        if (!practica.getTutorEmpresa().getEmail().equals(emailTutor)) {
            throw new AccessDeniedException("No eres el tutor de empresa de esta práctica");
        }

        Usuario tutorEmpresa = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        // Upsert: si ya existe evaluación, se actualiza
        EvaluacionFinal evaluacion = evaluacionRepository.findByPracticaId(practicaId)
                .orElse(EvaluacionFinal.builder().practica(practica).build());

        evaluacion.setTutorEmpresa(tutorEmpresa);
        evaluacion.setActitudPuntualidad(request.actitudPuntualidad());
        evaluacion.setCompetenciaTecnica(request.competenciaTecnica());
        evaluacion.setIniciativaAutonomia(request.iniciativaAutonomia());
        evaluacion.setTrabajoEquipo(request.trabajoEquipo());
        evaluacion.setCumplimientoTareas(request.cumplimientoTareas());
        evaluacion.setNotaGlobal(request.notaGlobal());
        evaluacion.setComentario(request.comentario());

        EvaluacionFinal guardada = evaluacionRepository.save(evaluacion);

        auditService.registrar("EVALUACION_FINAL", "EVALUAR", guardada.getId(),
                "Practica=" + practicaId + " NotaGlobal=" + request.notaGlobal(), emailTutor);

        notificacionService.crear(practica.getAlumno().getId(), "EVALUACION",
                "Tu tutor de empresa ha registrado tu evaluación final: "
                        + request.notaGlobal() + "/10");
        notificacionService.crear(practica.getTutorCentro().getId(), "EVALUACION",
                "El tutor de empresa ha evaluado a " + practica.getAlumno().getNombre()
                        + ": " + request.notaGlobal() + "/10");

        return toResponse(guardada);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<EvaluacionFinalResponse> obtenerPorPractica(Long practicaId) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        boolean isAdmin = SecurityContextHolder.getContext().getAuthentication()
                .getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        Practica practica = practicaRepository.findById(practicaId)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        if (!isAdmin
                && !practica.getAlumno().getEmail().equals(email)
                && !practica.getTutorCentro().getEmail().equals(email)
                && !practica.getTutorEmpresa().getEmail().equals(email)) {
            throw new AccessDeniedException("No tienes acceso a esta evaluación");
        }

        return evaluacionRepository.findByPracticaId(practicaId).map(this::toResponse);
    }

    private EvaluacionFinalResponse toResponse(EvaluacionFinal e) {
        String alumnoNombre = e.getPractica().getAlumno().getNombre()
                + " " + e.getPractica().getAlumno().getApellidos();
        String tutorNombre = e.getTutorEmpresa().getNombre()
                + " " + e.getTutorEmpresa().getApellidos();
        return new EvaluacionFinalResponse(
                e.getId(),
                e.getPractica().getId(),
                alumnoNombre,
                e.getActitudPuntualidad(),
                e.getCompetenciaTecnica(),
                e.getIniciativaAutonomia(),
                e.getTrabajoEquipo(),
                e.getCumplimientoTareas(),
                e.getNotaGlobal(),
                e.getComentario(),
                e.getTutorEmpresa().getId(),
                tutorNombre,
                e.getFechaEvaluacion()
        );
    }
}
