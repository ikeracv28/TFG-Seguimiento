package com.tfg.api.models.mapper;

import com.tfg.api.models.dto.EmpresaResponse;
import com.tfg.api.models.entity.Empresa;
import org.mapstruct.Mapper;

/**
 * Mapper para la entidad Empresa.
 */
@Mapper(componentModel = "spring")
public interface EmpresaMapper {
    
    EmpresaResponse toResponse(Empresa empresa);
}
