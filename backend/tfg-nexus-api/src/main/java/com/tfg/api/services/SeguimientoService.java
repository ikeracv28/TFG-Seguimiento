package com.tfg.api.services;

import com.tfg.api.models.dto.SeguimientoRequest;
import com.tfg.api.models.dto.SeguimientoResponse;
import java.util.List;

/**
 * Interfaz que define las operaciones de negocio para los seguimientos.
 */
public interface SeguimientoService {

    /**
     * Registra una nueva actividad diaria.
     */
    SeguimientoResponse registrar(SeguimientoRequest request);

    /**
     * Recupera el historial de seguimientos de una práctica.
     */
    List<SeguimientoResponse> listarPorPractica(Long practicaId);

    /**
     * Permite a un tutor validar o rechazar un seguimiento.
     */
    SeguimientoResponse validar(Long id, String nuevoEstado, String comentario);

    /**
     * Elimina un registro (solo si está en estado PENDIENTE).
     */
    void eliminar(Long id);
}
