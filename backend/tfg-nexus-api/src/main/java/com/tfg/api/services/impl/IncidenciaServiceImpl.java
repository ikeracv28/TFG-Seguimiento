package com.tfg.api.services.impl;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.IncidenciaRequest;
import com.tfg.api.models.dto.IncidenciaResponse;
import com.tfg.api.models.entity.Incidencia;
import com.tfg.api.models.mapper.IncidenciaMapper;
import com.tfg.api.models.repository.IncidenciaRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.AuditService;
import com.tfg.api.services.IncidenciaService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class IncidenciaServiceImpl implements IncidenciaService {

    private final IncidenciaRepository incidenciaRepository;
    private final UsuarioRepository usuarioRepository;
    private final PracticaRepository practicaRepository;
    private final IncidenciaMapper incidenciaMapper;
    private final AuditService auditService;

    private static final List<String> ORDEN_ESTADOS =
            List.of("ABIERTA", "EN_PROCESO", "RESUELTA", "CERRADA");

    @Override
    @Transactional
    public IncidenciaResponse crear(IncidenciaRequest request, String emailUsuario) {
        var usuario = usuarioRepository.findByEmail(emailUsuario)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
        var practica = practicaRepository.findFirstByAlumnoIdAndEstado(usuario.getId(), "ACTIVA")
                .orElseThrow(() -> new BusinessRuleException("No tienes una práctica activa"));

        var incidencia = Incidencia.builder()
                .practica(practica)
                .creadaPor(usuario)
                .tipo(request.tipo())
                .descripcion(request.descripcion())
                .estado("ABIERTA")
                .build();

        IncidenciaResponse creada = incidenciaMapper.toResponse(incidenciaRepository.save(incidencia));
        auditService.registrar("INCIDENCIAS", "CREAR", creada.id(),
                "Tipo=" + request.tipo() + " practica=" + practica.getId(), emailUsuario);
        return creada;
    }

    @Override
    @Transactional(readOnly = true)
    public List<IncidenciaResponse> listarPorPractica(Long practicaId) {
        return incidenciaMapper.toResponseList(
                incidenciaRepository.findByPracticaIdOrderByFechaCreacionDesc(practicaId));
    }

    @Override
    @Transactional(readOnly = true)
    public IncidenciaResponse obtenerPorId(Long id) {
        return incidenciaMapper.toResponse(
                incidenciaRepository.findById(id)
                        .orElseThrow(() -> new ResourceNotFoundException("Incidencia no encontrada")));
    }

    @Override
    @Transactional
    public IncidenciaResponse actualizarEstado(Long id, String nuevoEstado, String emailTutor) {
        var incidencia = incidenciaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Incidencia no encontrada"));

        int indiceActual = ORDEN_ESTADOS.indexOf(incidencia.getEstado());
        int indiceNuevo = ORDEN_ESTADOS.indexOf(nuevoEstado);

        if (indiceNuevo == -1) {
            throw new BusinessRuleException("Estado no válido: " + nuevoEstado);
        }
        if (indiceActual >= ORDEN_ESTADOS.size() - 1) {
            throw new BusinessRuleException("La incidencia está cerrada y no puede modificarse");
        }
        if (indiceNuevo <= indiceActual) {
            throw new BusinessRuleException("No se puede retroceder el estado de una incidencia");
        }

        var tutor = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        incidencia.setEstado(nuevoEstado);
        incidencia.setResueltaPor(tutor);

        if (nuevoEstado.equals("RESUELTA") || nuevoEstado.equals("CERRADA")) {
            if (incidencia.getFechaResolucion() == null) {
                incidencia.setFechaResolucion(LocalDateTime.now());
            }
        }

        IncidenciaResponse actualizada = incidenciaMapper.toResponse(incidenciaRepository.save(incidencia));
        auditService.registrar("INCIDENCIAS", "CAMBIAR_ESTADO", id,
                "Incidencia → " + nuevoEstado, emailTutor);
        return actualizada;
    }
}
