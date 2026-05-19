package com.tfg.api.services;

import com.tfg.api.models.dto.EmpresaRequest;
import com.tfg.api.models.dto.EmpresaResponse;
import java.util.List;

public interface EmpresaService {
    List<EmpresaResponse> findAll();
    EmpresaResponse create(EmpresaRequest request);
    EmpresaResponse update(Long id, EmpresaRequest request);
    void delete(Long id);
}
