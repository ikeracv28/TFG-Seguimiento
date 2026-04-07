package com.tfg.api.services.impl;

import com.tfg.api.models.dto.CentroResponse;
import com.tfg.api.models.mapper.CentroMapper;
import com.tfg.api.models.repository.CentroRepository;
import com.tfg.api.services.CentroService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Implementación de los servicios de gestión de centros educativos.
 * Realiza la comunicación con el repositorio de centros y el mapeo a DTOs de respuesta.
 */
@Service
@RequiredArgsConstructor
public class CentroServiceImpl implements CentroService {

    private final CentroRepository centroRepository;
    private final CentroMapper centroMapper;

    @Override
    public List<CentroResponse> findAll() {
        return centroRepository.findAll().stream()
                .map(centroMapper::toResponse)
                .collect(Collectors.toList());
    }
}
