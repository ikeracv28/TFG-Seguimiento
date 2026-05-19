package com.tfg.api.models.entity;

/**
 * Estados válidos que el tutor de empresa puede asignar al validar un seguimiento.
 * Reemplaza el parámetro String libre en validarEmpresa() — A04/OWASP.
 */
public enum EstadoValidacionEmpresa {
    PENDIENTE_CENTRO,
    RECHAZADO;

    public String valor() {
        return this.name();
    }
}
