package com.tfg.api.services;

import com.tfg.api.models.dto.EmpresaResponse;
import java.util.List;

/**
 * Servicio para la gestión de empresas colaboradoras.
 */
public interface EmpresaService {
    List<EmpresaResponse> findAll();
}
