package com.tfg.api.services;

import com.tfg.api.models.dto.SeguimientoRequest;
import com.tfg.api.models.dto.SeguimientoResponse;
import java.util.List;

/**
 * Interfaz que define las operaciones de negocio para los seguimientos.
 */
public interface SeguimientoService {

    SeguimientoResponse registrar(SeguimientoRequest request);

    List<SeguimientoResponse> listarPorPractica(Long practicaId);

    /**
     * Primera validación: tutor de empresa aprueba (PENDIENTE_CENTRO) o rechaza (RECHAZADO).
     * El rechazo genera automáticamente una incidencia de tipo RECHAZO_PARTE.
     */
    SeguimientoResponse validarEmpresa(Long id, String nuevoEstado, String motivo);

    /**
     * Segunda y definitiva validación: tutor del centro marca el parte como COMPLETADO.
     * Solo actúa sobre partes en estado PENDIENTE_CENTRO.
     */
    SeguimientoResponse validarCentro(Long id);

    void eliminar(Long id);
}
