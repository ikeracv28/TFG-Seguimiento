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
import com.tfg.api.services.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
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
    private final NotificacionService notificacionService;

    @Override
    @Transactional
    public MensajeResponse guardar(MensajeRequest request, String emailRemitente, Long practicaId, String canal) {
        Practica practica = practicaRepository.findById(practicaId)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        Usuario remitente = usuarioRepository.findByEmail(emailRemitente)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        String canalEfectivo = (canal != null && !canal.isBlank()) ? canal.toUpperCase() : "ALUMNO";

        // A01: verificar que el remitente puede usar este canal
        validarAccesoCanal(practica, emailRemitente, canalEfectivo);

        Mensaje mensaje = Mensaje.builder()
                .practica(practica)
                .remitente(remitente)
                .contenido(request.contenido())
                .canal(canalEfectivo)
                .tipo("TEXTO")
                .build();

        Mensaje guardado = mensajeRepository.save(mensaje);
        auditService.registrar("MENSAJES", "ENVIAR", guardado.getId(),
                "Practica=" + practicaId + " Canal=" + canalEfectivo, emailRemitente);

        String nombreRemitente = remitente.getNombre() + " " + remitente.getApellidos();
        enviarNotificacion(practica, emailRemitente, canalEfectivo, nombreRemitente);

        return toResponse(guardado);
    }

    @Override
    @Transactional(readOnly = true)
    public List<MensajeResponse> listarPorPractica(Long practicaId, String canal) {
        Practica practica = practicaRepository.findById(practicaId)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        String canalEfectivo = (canal != null && !canal.isBlank()) ? canal.toUpperCase() : "ALUMNO";

        if (!isAdmin) {
            validarAccesoCanal(practica, email, canalEfectivo);
        }

        return mensajeRepository
                .findByPracticaIdAndCanalOrderByFechaEnvioAsc(practicaId, canalEfectivo)
                .stream().map(this::toResponse).toList();
    }

    private void validarAccesoCanal(Practica practica, String email, String canal) {
        boolean acceso = switch (canal) {
            case "TUTORES" ->
                email.equals(practica.getTutorCentro().getEmail())
                || email.equals(practica.getTutorEmpresa().getEmail());
            default -> // ALUMNO
                email.equals(practica.getAlumno().getEmail())
                || email.equals(practica.getTutorCentro().getEmail());
        };
        if (!acceso) {
            throw new BusinessRuleException("No tienes acceso al canal " + canal + " de esta práctica");
        }
    }

    private void enviarNotificacion(Practica practica, String emailRemitente,
                                    String canal, String nombreRemitente) {
        Long destinatarioId;
        if ("TUTORES".equals(canal)) {
            // Tutor empresa → notifica tutor centro; tutor centro → notifica tutor empresa
            destinatarioId = emailRemitente.equals(practica.getTutorEmpresa().getEmail())
                    ? practica.getTutorCentro().getId()
                    : practica.getTutorEmpresa().getId();
        } else {
            // Canal ALUMNO: alumno → tutor centro; tutor centro → alumno
            destinatarioId = emailRemitente.equals(practica.getAlumno().getEmail())
                    ? practica.getTutorCentro().getId()
                    : practica.getAlumno().getId();
        }
        notificacionService.crear(destinatarioId, "CHAT",
                "Nuevo mensaje de " + nombreRemitente + " en tu práctica.");
    }

    @Override
    @Transactional
    public MensajeResponse guardarAdjunto(Long practicaId, String canal, String emailRemitente,
                                          byte[] datos, String nombre, String mimeType) {
        if (datos == null || datos.length == 0) {
            throw new BusinessRuleException("El adjunto no puede estar vacío");
        }
        if (datos.length > 10 * 1024 * 1024) {
            throw new BusinessRuleException("El adjunto supera el límite de 10 MB");
        }

        Practica practica = practicaRepository.findById(practicaId)
                .orElseThrow(() -> new ResourceNotFoundException("Práctica no encontrada"));

        Usuario remitente = usuarioRepository.findByEmail(emailRemitente)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        String canalEfectivo = (canal != null && !canal.isBlank()) ? canal.toUpperCase() : "ALUMNO";
        validarAccesoCanal(practica, emailRemitente, canalEfectivo);

        Mensaje mensaje = Mensaje.builder()
                .practica(practica)
                .remitente(remitente)
                .contenido("")
                .canal(canalEfectivo)
                .tipo("ADJUNTO")
                .adjuntoNombre(nombre)
                .adjuntoDatos(datos)
                .adjuntoTipo(mimeType)
                .build();

        Mensaje guardado = mensajeRepository.save(mensaje);
        auditService.registrar("MENSAJES", "ADJUNTO", guardado.getId(),
                "Practica=" + practicaId + " Canal=" + canalEfectivo + " Fichero=" + nombre, emailRemitente);

        String nombreRemitente = remitente.getNombre() + " " + remitente.getApellidos();
        enviarNotificacion(practica, emailRemitente, canalEfectivo, nombreRemitente);

        return toResponse(guardado);
    }

    @Override
    @Transactional(readOnly = true)
    public ResponseEntity<byte[]> descargarAdjunto(Long mensajeId, String emailSolicitante) {
        Mensaje mensaje = mensajeRepository.findById(mensajeId)
                .orElseThrow(() -> new ResourceNotFoundException("Mensaje no encontrado"));

        if (!"ADJUNTO".equals(mensaje.getTipo()) || mensaje.getAdjuntoDatos() == null) {
            throw new BusinessRuleException("El mensaje no tiene adjunto");
        }

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (!isAdmin) {
            validarAccesoCanal(mensaje.getPractica(), emailSolicitante, mensaje.getCanal());
        }

        String mime = mensaje.getAdjuntoTipo() != null ? mensaje.getAdjuntoTipo() : "application/octet-stream";
        String nombre = mensaje.getAdjuntoNombre() != null ? mensaje.getAdjuntoNombre() : "adjunto";

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(mime))
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + nombre + "\"")
                .body(mensaje.getAdjuntoDatos());
    }

    private MensajeResponse toResponse(Mensaje m) {
        return new MensajeResponse(
                m.getId(),
                m.getPractica().getId(),
                m.getRemitente().getId(),
                m.getRemitente().getNombre(),
                m.getRemitente().getApellidos(),
                m.getContenido() != null ? m.getContenido() : "",
                m.getFechaEnvio(),
                m.getCanal(),
                m.getTipo() != null ? m.getTipo() : "TEXTO",
                m.getAdjuntoNombre());
    }
}
