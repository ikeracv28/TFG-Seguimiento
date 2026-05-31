package com.tfg.api.services.impl;

import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.PlanificarTutoriasRequest;
import com.tfg.api.models.dto.TutoriaResponse;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Tutoria;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.TutoriaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.EmailService;
import com.tfg.api.services.TutoriaService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TutoriaServiceImpl implements TutoriaService {

    private final TutoriaRepository tutoriaRepository;
    private final UsuarioRepository usuarioRepository;
    private final PracticaRepository practicaRepository;
    private final EmailService emailService;

    @Override
    @Transactional
    public List<TutoriaResponse> planificar(PlanificarTutoriasRequest req, String emailTutor) {
        Usuario tutor = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Tutor no encontrado"));

        List<Usuario> alumnos = practicaRepository.findByTutorCentroId(tutor.getId())
                .stream()
                .map(Practica::getAlumno)
                .distinct()
                .collect(Collectors.toList());

        if (req.ordenAlumnosIds() != null && !req.ordenAlumnosIds().isEmpty()) {
            Map<Long, Integer> orden = new HashMap<>();
            for (int i = 0; i < req.ordenAlumnosIds().size(); i++) {
                orden.put(req.ordenAlumnosIds().get(i), i);
            }
            alumnos.sort(Comparator.comparingInt(a -> orden.getOrDefault(a.getId(), 999)));
        }

        LocalDateTime inicioDia = req.fecha().atStartOfDay();
        LocalDateTime finDia = req.fecha().plusDays(1).atStartOfDay();
        tutoriaRepository.deleteByTutorCentroIdAndFechaHoraBetween(tutor.getId(), inicioDia, finDia);

        List<Tutoria> nuevas = new ArrayList<>();
        LocalDateTime slot = LocalDateTime.of(req.fecha(), req.horaInicio());
        for (Usuario alumno : alumnos) {
            nuevas.add(Tutoria.builder()
                    .tutorCentro(tutor)
                    .alumno(alumno)
                    .fechaHora(slot)
                    .duracionMinutos(req.duracionMinutos())
                    .build());
            slot = slot.plusMinutes(req.duracionMinutos());
        }

        return tutoriaRepository.saveAll(nuevas).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<TutoriaResponse> getMisSesiones(String emailTutor) {
        Usuario tutor = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Tutor no encontrado"));
        return tutoriaRepository.findByTutorCentroIdOrderByFechaHoraAsc(tutor.getId())
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public TutoriaResponse getProximaTutoriaAlumno(String emailAlumno) {
        Usuario alumno = usuarioRepository.findByEmail(emailAlumno)
                .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado"));
        return tutoriaRepository
                .findFirstByAlumnoIdAndFechaHoraAfterOrderByFechaHoraAsc(alumno.getId(), LocalDateTime.now())
                .map(this::toResponse)
                .orElse(null);
    }

    @Override
    @Transactional
    public int enviarNotificaciones(LocalDate fecha, String emailTutor) {
        Usuario tutor = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Tutor no encontrado"));

        LocalDateTime inicio = fecha.atStartOfDay();
        LocalDateTime fin = fecha.plusDays(1).atStartOfDay();
        String nombreTutor = tutor.getNombre() + " " + tutor.getApellidos();

        List<Tutoria> slots = tutoriaRepository
                .findByTutorCentroIdOrderByFechaHoraAsc(tutor.getId())
                .stream()
                .filter(t -> !t.getFechaHora().isBefore(inicio) && t.getFechaHora().isBefore(fin))
                .collect(Collectors.toList());

        int enviados = 0;
        for (Tutoria t : slots) {
            emailService.enviarConvocatoriaTutoria(
                    t.getAlumno().getEmail(),
                    t.getAlumno().getNombre(),
                    t.getFechaHora(),
                    nombreTutor);
            t.setNotificado(true);
            enviados++;
        }
        tutoriaRepository.saveAll(slots);
        return enviados;
    }

    @Override
    @Transactional
    public void eliminarSesion(LocalDate fecha, String emailTutor) {
        Usuario tutor = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Tutor no encontrado"));
        LocalDateTime inicio = fecha.atStartOfDay();
        LocalDateTime fin = fecha.plusDays(1).atStartOfDay();
        tutoriaRepository.deleteByTutorCentroIdAndFechaHoraBetween(tutor.getId(), inicio, fin);
    }

    private TutoriaResponse toResponse(Tutoria t) {
        String nombre = t.getAlumno().getNombre() + " " + t.getAlumno().getApellidos();
        return new TutoriaResponse(
                t.getId(),
                t.getAlumno().getId(),
                nombre,
                t.getAlumno().getEmail(),
                t.getFechaHora(),
                t.getDuracionMinutos(),
                t.getNotificado());
    }
}
