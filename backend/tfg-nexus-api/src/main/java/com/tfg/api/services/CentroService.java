package com.tfg.api.services;

import com.tfg.api.models.dto.CentroResponse;
import java.util.List;

/**
 * Servicio para la gestión de centros educativos.
 */
public interface CentroService {
    List<CentroResponse> findAll();
}
