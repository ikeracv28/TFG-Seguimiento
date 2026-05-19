package com.tfg.api.services.impl;

import com.tfg.api.exceptions.ResourceNotFoundException;
import com.tfg.api.models.dto.EmpresaRequest;
import com.tfg.api.models.dto.EmpresaResponse;
import com.tfg.api.models.entity.Empresa;
import com.tfg.api.models.mapper.EmpresaMapper;
import com.tfg.api.models.repository.EmpresaRepository;
import com.tfg.api.services.EmpresaService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EmpresaServiceImpl implements EmpresaService {

    private final EmpresaRepository empresaRepository;
    private final EmpresaMapper empresaMapper;

    @Override
    public List<EmpresaResponse> findAll() {
        return empresaRepository.findAll().stream()
                .map(empresaMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public EmpresaResponse create(EmpresaRequest request) {
        if (empresaRepository.existsByCif(request.cif())) {
            throw new IllegalArgumentException("Ya existe una empresa con el CIF " + request.cif());
        }
        Empresa empresa = empresaMapper.toEntity(request);
        return empresaMapper.toResponse(empresaRepository.save(empresa));
    }

    @Override
    @Transactional
    public EmpresaResponse update(Long id, EmpresaRequest request) {
        Empresa empresa = empresaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Empresa no encontrada: " + id));

        empresaRepository.findByCif(request.cif())
                .filter(e -> !e.getId().equals(id))
                .ifPresent(e -> { throw new IllegalArgumentException("El CIF ya está en uso por otra empresa"); });

        empresaMapper.updateEntity(request, empresa);
        return empresaMapper.toResponse(empresaRepository.save(empresa));
    }

    @Override
    @Transactional
    public void delete(Long id) {
        if (!empresaRepository.existsById(id)) {
            throw new ResourceNotFoundException("Empresa no encontrada: " + id);
        }
        empresaRepository.deleteById(id);
    }
}
