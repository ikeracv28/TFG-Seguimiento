package com.tfg.api.models.mapper;

import com.tfg.api.models.dto.EmpresaResponse;
import com.tfg.api.models.entity.Empresa;
import org.mapstruct.Mapper;

/**
 * Interface para mapear la entidad Empresa a su DTO de respuesta.
 */
@Mapper(componentModel = "spring")
public interface EmpresaMapper {
    
    EmpresaResponse toResponse(Empresa empresa);
}
