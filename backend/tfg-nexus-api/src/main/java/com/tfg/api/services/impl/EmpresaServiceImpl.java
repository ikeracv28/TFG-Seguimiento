package com.tfg.api.services.impl;

import com.tfg.api.models.dto.EmpresaResponse;
import com.tfg.api.models.mapper.EmpresaMapper;
import com.tfg.api.models.repository.EmpresaRepository;
import com.tfg.api.services.EmpresaService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Implementación de los servicios relacionados con la gestión de empresas colaboradoras.
 */
@Service
@RequiredArgsConstructor
public class EmpresaServiceImpl implements EmpresaService {

    private final EmpresaRepository empresaRepository;
    private final EmpresaMapper empresaMapper;

    /**
     * Recupera y transforma todas las empresas registradas para su uso en la capa de presentación.
     */
    @Override
    public List<EmpresaResponse> findAll() {
        return empresaRepository.findAll().stream()
                .map(empresaMapper::toResponse)
                .collect(Collectors.toList());
    }
}
