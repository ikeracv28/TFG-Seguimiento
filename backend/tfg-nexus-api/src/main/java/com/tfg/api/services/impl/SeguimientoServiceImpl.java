package com.tfg.api.services.impl;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.SeguimientoRequest;
import com.tfg.api.models.dto.SeguimientoResponse;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Seguimiento;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.mapper.SeguimientoMapper;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.SeguimientoRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.SeguimientoService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Implementación de la lógica de negocio para los partes de seguimiento.
 */
@Service
@RequiredArgsConstructor
public class SeguimientoServiceImpl implements SeguimientoService {

    private final SeguimientoRepository seguimientoRepository;
    private final PracticaRepository practicaRepository;
    private final UsuarioRepository usuarioRepository;
    private final SeguimientoMapper seguimientoMapper;

    @Override
    @Transactional
    public SeguimientoResponse registrar(SeguimientoRequest request) {
        // Buscamos la práctica asociada
        Practica practica = practicaRepository.findById(request.practicaId())
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        // Creamos la entidad base
        Seguimiento seguimiento = seguimientoMapper.toEntity(request);
        seguimiento.setPractica(practica);
        seguimiento.setEstado("PENDIENTE");

        // Guardamos y devolvemos la respuesta
        Seguimiento guardado = seguimientoRepository.save(seguimiento);
        return seguimientoMapper.toResponse(guardado);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SeguimientoResponse> listarPorPractica(Long practicaId) {
        return seguimientoRepository.findByPracticaIdOrderByFechaRegistroDesc(practicaId)
                .stream()
                .map(seguimientoMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public SeguimientoResponse validar(Long id, String nuevoEstado, String comentario) {
        Seguimiento seguimiento = seguimientoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Seguimiento no encontrado"));

        // Obtenemos el tutor que realiza la acción desde el contexto de seguridad
        String emailTutor = SecurityContextHolder.getContext().getAuthentication().getName();
        Usuario tutor = usuarioRepository.findByEmail(emailTutor)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no identificado"));

        // Validamos el estado permitido
        if (!nuevoEstado.equals("VALIDADO") && !nuevoEstado.equals("RECHAZADO")) {
            throw new BusinessRuleException("Estado de validación no permitido");
        }

        seguimiento.setEstado(nuevoEstado);
        seguimiento.setValidadoPor(tutor);
        seguimiento.setComentarioTutor(comentario);

        return seguimientoMapper.toResponse(seguimientoRepository.save(seguimiento));
    }

    @Override
    @Transactional
    public void eliminar(Long id) {
        Seguimiento seguimiento = seguimientoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Seguimiento no encontrado"));

        // Regla: Solo se pueden borrar registros pendientes
        if (!"PENDIENTE".equals(seguimiento.getEstado())) {
            throw new BusinessRuleException("No se puede eliminar un registro ya validado o rechazado");
        }

        seguimientoRepository.delete(seguimiento);
    }
}
