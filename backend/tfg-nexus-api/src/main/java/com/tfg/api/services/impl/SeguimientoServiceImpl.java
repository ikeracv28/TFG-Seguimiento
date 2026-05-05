package com.tfg.api.services.impl;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.SeguimientoRequest;
import com.tfg.api.models.dto.SeguimientoResponse;
import com.tfg.api.models.entity.Incidencia;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Seguimiento;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.mapper.SeguimientoMapper;
import com.tfg.api.models.repository.IncidenciaRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.SeguimientoRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.AuditService;
import com.tfg.api.services.SeguimientoService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SeguimientoServiceImpl implements SeguimientoService {

    private static final Logger log = LoggerFactory.getLogger(SeguimientoServiceImpl.class);

    private final SeguimientoRepository seguimientoRepository;
    private final PracticaRepository practicaRepository;
    private final UsuarioRepository usuarioRepository;
    private final IncidenciaRepository incidenciaRepository;
    private final SeguimientoMapper seguimientoMapper;
    private final AuditService auditService;

    @Override
    @Transactional
    public SeguimientoResponse registrar(SeguimientoRequest request) {
        Practica practica = practicaRepository.findById(request.practicaId())
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        // A04: máximo 1 parte pendiente por semana ISO (lunes-domingo)
        LocalDate lunes = request.fechaRegistro().with(DayOfWeek.MONDAY);
        LocalDate domingo = request.fechaRegistro().with(DayOfWeek.SUNDAY);
        if (seguimientoRepository.existsByPracticaIdAndEstadoAndFechaRegistroBetween(
                request.practicaId(), "PENDIENTE_EMPRESA", lunes, domingo)) {
            throw new BusinessRuleException(
                "Ya tienes un parte pendiente de validación para esta semana. Espera a que sea procesado antes de registrar otro.");
        }

        Seguimiento seguimiento = seguimientoMapper.toEntity(request);
        seguimiento.setPractica(practica);
        seguimiento.setEstado("PENDIENTE_EMPRESA");

        SeguimientoResponse registrado = seguimientoMapper.toResponse(seguimientoRepository.save(seguimiento));
        String actor = currentUserEmail();
        auditService.registrar("SEGUIMIENTOS", "REGISTRAR", registrado.id(),
                "Fecha=" + request.fechaRegistro() + " practica=" + practica.getId(), actor);
        return registrado;
    }

    @Override
    @Transactional(readOnly = true)
    public List<SeguimientoResponse> listarPorPractica(Long practicaId) {
        Practica practica = practicaRepository.findById(practicaId)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        String email = currentUserEmail();
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        if (!isAdmin
                && !practica.getAlumno().getEmail().equals(email)
                && !practica.getTutorCentro().getEmail().equals(email)
                && !practica.getTutorEmpresa().getEmail().equals(email)) {
            throw new AccessDeniedException("No tienes acceso a los seguimientos de esta práctica");
        }

        return seguimientoRepository.findByPracticaIdOrderByFechaRegistroDesc(practicaId)
                .stream()
                .map(seguimientoMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public SeguimientoResponse validarEmpresa(Long id, String nuevoEstado, String motivo) {
        Seguimiento seguimiento = seguimientoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Seguimiento no encontrado"));

        if (!"PENDIENTE_EMPRESA".equals(seguimiento.getEstado())) {
            throw new BusinessRuleException("Este parte ya fue procesado por la empresa");
        }
        if (!"PENDIENTE_CENTRO".equals(nuevoEstado) && !"RECHAZADO".equals(nuevoEstado)) {
            throw new BusinessRuleException("Estado no válido para la empresa: " + nuevoEstado);
        }
        if ("RECHAZADO".equals(nuevoEstado) && (motivo == null || motivo.isBlank())) {
            throw new BusinessRuleException("El motivo es obligatorio al rechazar un parte");
        }

        String emailTutor = currentUserEmail();
        if (!seguimiento.getPractica().getTutorEmpresa().getEmail().equals(emailTutor)) {
            throw new AccessDeniedException("No tienes permiso para validar este parte");
        }

        Usuario tutorEmpresa = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no identificado"));

        seguimiento.setEstado(nuevoEstado);
        seguimiento.setValidadoPor(tutorEmpresa);
        seguimiento.setComentarioTutor(motivo);

        if ("RECHAZADO".equals(nuevoEstado)) {
            log.info("SEGUIMIENTO_RECHAZADO id={} por_tutor={} motivo={}", id, emailTutor, motivo);
            crearIncidenciaRechazo(seguimiento.getPractica(), tutorEmpresa, motivo);
        } else {
            log.info("SEGUIMIENTO_VALIDADO_EMPRESA id={} por_tutor={}", id, emailTutor);
        }

        SeguimientoResponse validado = seguimientoMapper.toResponse(seguimientoRepository.save(seguimiento));
        auditService.registrar("SEGUIMIENTOS", "VALIDAR_EMPRESA_" + nuevoEstado, id,
                "Seguimiento → " + nuevoEstado, emailTutor);
        return validado;
    }

    @Override
    @Transactional
    public SeguimientoResponse validarCentro(Long id) {
        Seguimiento seguimiento = seguimientoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Seguimiento no encontrado"));

        if (!"PENDIENTE_CENTRO".equals(seguimiento.getEstado())) {
            throw new BusinessRuleException(
                    "El parte debe ser validado por la empresa antes de que el centro actúe");
        }

        String emailTutor = currentUserEmail();
        if (!seguimiento.getPractica().getTutorCentro().getEmail().equals(emailTutor)) {
            throw new AccessDeniedException("No tienes permiso para validar este parte");
        }

        Usuario tutorCentro = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no identificado"));

        seguimiento.setEstado("COMPLETADO");
        seguimiento.setValidadoPor(tutorCentro);
        log.info("SEGUIMIENTO_COMPLETADO id={} por_tutor={}", id, emailTutor);

        SeguimientoResponse completado = seguimientoMapper.toResponse(seguimientoRepository.save(seguimiento));
        auditService.registrar("SEGUIMIENTOS", "VALIDAR_CENTRO", id,
                "Seguimiento completado", emailTutor);
        return completado;
    }

    @Override
    @Transactional
    public void eliminar(Long id) {
        Seguimiento seguimiento = seguimientoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Seguimiento no encontrado"));

        if (!"PENDIENTE_EMPRESA".equals(seguimiento.getEstado())) {
            throw new BusinessRuleException("No se puede eliminar un registro ya procesado");
        }

        seguimientoRepository.delete(seguimiento);
    }

    private String currentUserEmail() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null) ? auth.getName() : "system";
    }

    private void crearIncidenciaRechazo(Practica practica, Usuario tutorEmpresa, String motivo) {
        Incidencia incidencia = Incidencia.builder()
                .practica(practica)
                .creadaPor(tutorEmpresa)
                .tipo("RECHAZO_PARTE")
                .descripcion("Parte rechazado. Motivo: " + motivo)
                .estado("ABIERTA")
                .build();
        incidenciaRepository.save(incidencia);
    }
}
