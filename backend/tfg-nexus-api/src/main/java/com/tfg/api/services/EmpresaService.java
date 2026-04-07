package com.tfg.api.services;

import com.tfg.api.models.dto.EmpresaResponse;
import java.util.List;

/**
 * Interfaz de servicio dedicada a la gestión de las empresas colaboradoras del programa.
 */
public interface EmpresaService {
    /**
     * Obtiene el listado completo de todas las entidades colaboradoras registradas.
     */
    List<EmpresaResponse> findAll();
}
