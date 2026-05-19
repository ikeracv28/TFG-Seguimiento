package com.tfg.api.models.mapper;

import com.tfg.api.models.dto.EmpresaRequest;
import com.tfg.api.models.dto.EmpresaResponse;
import com.tfg.api.models.entity.Empresa;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

@Mapper(componentModel = "spring")
public interface EmpresaMapper {

    EmpresaResponse toResponse(Empresa empresa);

    Empresa toEntity(EmpresaRequest request);

    void updateEntity(EmpresaRequest request, @MappingTarget Empresa empresa);
}
