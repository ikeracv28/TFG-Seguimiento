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
@Service
@RequiredArgsConstructor
public class PracticaServiceImpl implements PracticaService {

    private final PracticaRepository practicaRepository;
    private final UsuarioRepository usuarioRepository;
    private final EmpresaRepository empresaRepository;
    private final PracticaMapper practicaMapper;

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

        return practicaMapper.toResponse(practicaRepository.save(practica));
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

        return practicaMapper.toResponse(practicaRepository.save(practica));
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

        practicaRepository.delete(practica);
    }

    @Override
    @Transactional
    public PracticaResponse cambiarEstado(Long id, String nuevoEstado) {
        Practica practica = practicaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        practica.setEstado(nuevoEstado.toUpperCase());
        return practicaMapper.toResponse(practicaRepository.save(practica));
    }

    @Override
    @Transactional(readOnly = true)
    public PracticaResponse obtenerPracticaActivaDelAlumno() {
        // Obtenemos el email del alumno autenticado desde el JWT ya validado
        String email = SecurityContextHolder.getContext().getAuthentication().getName();

        var alumno = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario autenticado no encontrado"));

        return practicaRepository
                .findFirstByAlumnoIdAndEstado(alumno.getId(), "ACTIVA")
                .map(practicaMapper::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("No tienes ninguna práctica activa en este momento"));
    }
}
