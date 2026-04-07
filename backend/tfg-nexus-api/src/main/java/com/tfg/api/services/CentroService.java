package com.tfg.api.services;

import com.tfg.api.models.dto.CentroResponse;
import java.util.List;

/**
 * Definición de los servicios necesarios para la gestión y consulta de los centros educativos.
 */
public interface CentroService {
    /**
     * Recupera la lista completa de centros registrados en la base de datos.
     */
    List<CentroResponse> findAll();
}
