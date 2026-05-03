package com.tfg.api.services.impl;

import com.tfg.api.exceptions.BusinessRuleException;
import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.MensajeRequest;
import com.tfg.api.models.dto.MensajeResponse;
import com.tfg.api.models.entity.Mensaje;
import com.tfg.api.models.entity.Practica;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.MensajeRepository;
import com.tfg.api.models.repository.PracticaRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.AuditService;
import com.tfg.api.services.MensajeService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MensajeServiceImpl implements MensajeService {

    private final MensajeRepository mensajeRepository;
    private final PracticaRepository practicaRepository;
    private final UsuarioRepository usuarioRepository;
    private final AuditService auditService;

    @Override
    @Transactional
    public MensajeResponse guardar(MensajeRequest request, String emailRemitente, Long practicaId) {
        Practica practica = practicaRepository.findById(practicaId)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        Usuario remitente = usuarioRepository.findByEmail(emailRemitente)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        boolean esParticipante = emailRemitente.equals(practica.getAlumno().getEmail())
                || emailRemitente.equals(practica.getTutorCentro().getEmail())
                || emailRemitente.equals(practica.getTutorEmpresa().getEmail());
        if (!esParticipante) {
            throw new BusinessRuleException("No tienes acceso al chat de esta práctica");
        }

        Mensaje mensaje = Mensaje.builder()
                .practica(practica)
                .remitente(remitente)
                .contenido(request.contenido())
                .build();

        Mensaje guardado = mensajeRepository.save(mensaje);
        auditService.registrar("MENSAJES", "ENVIAR", guardado.getId(),
                "Practica=" + practicaId, emailRemitente);

        return toResponse(guardado);
    }

    @Override
    @Transactional(readOnly = true)
    public List<MensajeResponse> listarPorPractica(Long practicaId) {
        return mensajeRepository.findByPracticaIdOrderByFechaEnvioAsc(practicaId)
                .stream().map(this::toResponse).toList();
    }

    private MensajeResponse toResponse(Mensaje m) {
        return new MensajeResponse(
                m.getId(),
                m.getPractica().getId(),
                m.getRemitente().getId(),
                m.getRemitente().getNombre(),
                m.getRemitente().getApellidos(),
                m.getContenido(),
                m.getFechaEnvio());
    }
}
