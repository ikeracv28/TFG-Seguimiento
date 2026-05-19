package com.tfg.api.services.impl;

import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.NotificacionResponse;
import com.tfg.api.models.entity.Notificacion;
import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.NotificacionRepository;
import com.tfg.api.models.repository.UsuarioRepository;
import com.tfg.api.services.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificacionServiceImpl implements NotificacionService {

    private final NotificacionRepository notificacionRepository;
    private final UsuarioRepository usuarioRepository;

    @Override
    @Transactional
    public void crear(Long usuarioId, String tipo, String mensaje) {
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado: " + usuarioId));
        notificacionRepository.save(Notificacion.builder()
                .usuario(usuario)
                .tipo(tipo)
                .mensaje(mensaje)
                .leida(false)
                .build());
    }

    @Override
    @Transactional(readOnly = true)
    public List<NotificacionResponse> listarParaUsuario() {
        Long userId = getUsuarioAutenticado().getId();
        return notificacionRepository.findByUsuarioIdOrderByFechaCreacionDesc(userId)
                .stream()
                .map(n -> new NotificacionResponse(n.getId(), n.getTipo(), n.getMensaje(),
                        n.getLeida(), n.getFechaCreacion()))
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public long contarNoLeidas() {
        return notificacionRepository.countByUsuarioIdAndLeidaFalse(getUsuarioAutenticado().getId());
    }

    @Override
    @Transactional
    public void marcarLeida(Long id) {
        Long userId = getUsuarioAutenticado().getId();
        int updated = notificacionRepository.marcarLeida(id, userId);
        if (updated == 0) {
            throw new ResourceNotFoundException("Notificación no encontrada o no pertenece al usuario");
        }
    }

    @Override
    @Transactional
    public void marcarTodasLeidas() {
        notificacionRepository.marcarTodasLeidas(getUsuarioAutenticado().getId());
    }

    private Usuario getUsuarioAutenticado() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado: " + email));
    }
}
