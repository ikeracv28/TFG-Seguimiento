package com.tfg.api.services.impl;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.PracticaRequest;
import com.tfg.api.models.dto.PracticaResponse;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.mapper.PracticaMapper;
import com.tfg.api.models.repository.EmpresaRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.AuditService;
import com.tfg.api.services.PracticaService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

/**
 * Implementación del servicio de Prácticas.
 * Gestiona la lógica de negocio y las validaciones de integridad.
 */
@Service("practicaService")
@RequiredArgsConstructor
public class PracticaServiceImpl implements PracticaService {

    private final PracticaRepository practicaRepository;
    private final UsuarioRepository usuarioRepository;
    private final EmpresaRepository empresaRepository;
    private final PracticaMapper practicaMapper;
    private final AuditService auditService;

    @Override
    @Transactional
    public PracticaResponse crear(PracticaRequest request) {
        // Validamos la existencia de las entidades relacionadas
        var alumno = usuarioRepository.findById(request.alumnoId())
                .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado"));
        var tutorCentro = usuarioRepository.findById(request.tutorCentroId())
                .orElseThrow(() -> new ResourceNotFoundException("Tutor de centro no encontrado"));
        var tutorEmpresa = usuarioRepository.findById(request.tutorEmpresaId())
                .orElseThrow(() -> new ResourceNotFoundException("Tutor de empresa no encontrado"));
        var empresa = empresaRepository.findById(request.empresaId())
                .orElseThrow(() -> new ResourceNotFoundException("Empresa no encontrada"));

        // Comprobamos duplicados por código de expediente
        if (practicaRepository.existsByCodigo(request.codigo())) {
            throw new BusinessRuleException("Ya existe una práctica con el código: " + request.codigo());
        }

        Practica practica = practicaMapper.toEntity(request);
        practica.setAlumno(alumno);
        practica.setTutorCentro(tutorCentro);
        practica.setTutorEmpresa(tutorEmpresa);
        practica.setEmpresa(empresa);

        PracticaResponse creada = practicaMapper.toResponse(practicaRepository.save(practica));
        String actor = SecurityContextHolder.getContext().getAuthentication().getName();
        auditService.registrar("PRACTICAS", "CREAR", creada.id(),
                "Práctica " + request.codigo() + " alumno=" + alumno.getEmail(), actor);
        return creada;
    }

    @Override
    @Transactional(readOnly = true)
    public PracticaResponse obtenerPorId(Long id) {
        return practicaRepository.findById(id)
                .map(practicaMapper::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<PracticaResponse> listarTodas(Pageable pageable) {
        return practicaRepository.findAll(pageable).map(practicaMapper::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public List<PracticaResponse> listarPorAlumno(Long alumnoId) {
        return practicaMapper.toResponseList(practicaRepository.findByAlumnoId(alumnoId));
    }

    @Override
    @Transactional
    public PracticaResponse actualizar(Long id, PracticaRequest request) {
        Practica practica = practicaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        // Lógica de actualización selectiva o total según se requiera
        practica.setCodigo(request.codigo());
        practica.setFechaInicio(request.fechaInicio());
        practica.setFechaFin(request.fechaFin());
        practica.setHorasTotales(request.horasTotales());
        
        if (request.estado() != null) {
            practica.setEstado(request.estado());
        }

        PracticaResponse actualizada = practicaMapper.toResponse(practicaRepository.save(practica));
        String actor = SecurityContextHolder.getContext().getAuthentication().getName();
        auditService.registrar("PRACTICAS", "EDITAR", id,
                "Práctica " + practica.getCodigo() + " actualizada", actor);
        return actualizada;
    }

    @Override
    @Transactional
    public void eliminar(Long id) {
        Practica practica = practicaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));
        
        // No permitimos eliminar prácticas que ya estén activas o finalizadas
        if (!"BORRADOR".equals(practica.getEstado())) {
            throw new BusinessRuleException("No se puede eliminar una práctica que no esté en estado BORRADOR");
        }

        String actor = SecurityContextHolder.getContext().getAuthentication().getName();
        auditService.registrar("PRACTICAS", "ELIMINAR", id,
                "Práctica " + practica.getCodigo() + " eliminada (estado BORRADOR)", actor);
        practicaRepository.delete(practica);
    }

    private static final java.util.Set<String> ESTADOS_PRACTICA =
            java.util.Set.of("BORRADOR", "ACTIVA", "FINALIZADA");

    @Override
    @Transactional
    public PracticaResponse cambiarEstado(Long id, String nuevoEstado) {
        String estado = nuevoEstado.toUpperCase();
        if (!ESTADOS_PRACTICA.contains(estado)) {
            throw new BusinessRuleException(
                "Estado no válido. Los estados permitidos son: BORRADOR, ACTIVA, FINALIZADA");
        }
        Practica practica = practicaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));
        practica.setEstado(estado);
        PracticaResponse resp = practicaMapper.toResponse(practicaRepository.save(practica));
        String actor = SecurityContextHolder.getContext().getAuthentication().getName();
        auditService.registrar("PRACTICAS", "CAMBIAR_ESTADO", id,
                "Práctica " + practica.getCodigo() + " → " + estado, actor);
        return resp;
    }

    @Override
    @Transactional(readOnly = true)
    public PracticaResponse obtenerPracticaActivaDelAlumno() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        var alumno = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario autenticado no encontrado"));
        return practicaRepository
                .findFirstByAlumnoIdAndEstado(alumno.getId(), "ACTIVA")
                .map(practicaMapper::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("No tienes ninguna práctica activa en este momento"));
    }

    @Override
    @Transactional(readOnly = true)
    public List<PracticaResponse> listarMisPracticasComoTutorEmpresa() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        var tutor = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario autenticado no encontrado"));
        return practicaMapper.toResponseList(practicaRepository.findByTutorEmpresaId(tutor.getId()));
    }

    @Override
    @Transactional(readOnly = true)
    public List<PracticaResponse> listarMisPracticasComoTutorCentro() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        var tutor = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario autenticado no encontrado"));
        return practicaMapper.toResponseList(practicaRepository.findByTutorCentroId(tutor.getId()));
    }

    @Override
    @Transactional(readOnly = true)
    public boolean perteneceAlAlumnoAutenticado(Long alumnoId, String email) {
        return usuarioRepository.findByEmail(email)
                .map(u -> u.getId().equals(alumnoId))
                .orElse(false);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean esParticipante(Long practicaId, String email) {
        return practicaRepository.findById(practicaId)
                .map(p -> email.equals(p.getAlumno().getEmail())
                        || email.equals(p.getTutorCentro().getEmail())
                        || email.equals(p.getTutorEmpresa().getEmail()))
                .orElse(false);
    }
}
