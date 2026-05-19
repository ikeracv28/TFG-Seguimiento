package com.tfg.api.services;

import com.tfg.api.models.dto.NotificacionResponse;

import java.util.List;

public interface NotificacionService {

    void crear(Long usuarioId, String tipo, String mensaje);

    List<NotificacionResponse> listarParaUsuario();

    long contarNoLeidas();

    void marcarLeida(Long id);

    void marcarTodasLeidas();
}
