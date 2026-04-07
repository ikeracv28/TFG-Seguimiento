package com.tfg.api.models.mapper;

import com.tfg.api.models.dto.CentroResponse;
import com.tfg.api.models.entity.Centro;
import org.mapstruct.Mapper;

/**
 * Interface para mapear la entidad Centro a su DTO de respuesta.
 */
@Mapper(componentModel = "spring")
public interface CentroMapper {
    
    CentroResponse toResponse(Centro centro);
}
