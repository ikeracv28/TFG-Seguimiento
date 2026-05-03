package com.tfg.api.services;

import com.tfg.api.models.dto.AuditLogResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
@ActiveProfiles("test")
class AuditServiceTest {

    @Autowired private AuditService auditService;

    @Test
    @DisplayName("Registrar un log de auditoria persiste el registro")
    void registrar_persiste_log() {
        auditService.registrar("USUARIOS", "CREAR", 1L, "Usuario creado", "admin@test.com");

        Page<AuditLogResponse> logs = auditService.listar("USUARIOS", PageRequest.of(0, 10));

        assertThat(logs.getTotalElements()).isGreaterThanOrEqualTo(1);
        assertThat(logs.getContent()).anyMatch(l ->
                l.modulo().equals("USUARIOS") && l.accion().equals("CREAR"));
    }

    @Test
    @DisplayName("Listar sin filtro de modulo devuelve todos los logs")
    void listar_sin_modulo_devuelve_todos() {
        auditService.registrar("PRACTICAS", "EDITAR", 10L, "Practica editada", "admin@test.com");
        auditService.registrar("AUSENCIAS", "REGISTRAR", 20L, "Ausencia registrada", "alumno@test.com");

        Page<AuditLogResponse> todos = auditService.listar(null, PageRequest.of(0, 50));

        assertThat(todos.getTotalElements()).isGreaterThanOrEqualTo(2);
    }

    @Test
    @DisplayName("Filtro por modulo devuelve solo los logs de ese modulo")
    void filtro_por_modulo_filtra_correctamente() {
        auditService.registrar("INCIDENCIAS", "CREAR", 5L, "Incidencia abierta", "alumno@test.com");
        auditService.registrar("SEGUIMIENTOS", "REGISTRAR", 6L, "Seguimiento registrado", "alumno@test.com");

        Page<AuditLogResponse> soloIncidencias = auditService.listar("INCIDENCIAS", PageRequest.of(0, 10));

        assertThat(soloIncidencias.getContent()).allMatch(l -> l.modulo().equals("INCIDENCIAS"));
    }

    @Test
    @DisplayName("Registrar log sin entidadId (null) no lanza excepcion")
    void registrar_sin_entidad_id_es_valido() {
        auditService.registrar("MENSAJES", "ENVIAR", null, "Mensaje enviado", "usuario@test.com");

        Page<AuditLogResponse> logs = auditService.listar("MENSAJES", PageRequest.of(0, 10));

        assertThat(logs.getTotalElements()).isGreaterThanOrEqualTo(1);
    }

    @Test
    @DisplayName("El campo fecha se rellena automaticamente al persistir")
    void fecha_se_rellena_automaticamente() {
        auditService.registrar("USUARIOS", "ACTIVAR", 7L, "Usuario activado", "admin@test.com");

        Page<AuditLogResponse> logs = auditService.listar("USUARIOS", PageRequest.of(0, 10));

        assertThat(logs.getContent()).anyMatch(l -> l.fecha() != null);
    }

    @Test
    @DisplayName("El filtro de modulo es case-insensitive (se normaliza a mayusculas)")
    void filtro_modulo_normaliza_a_mayusculas() {
        auditService.registrar("PRACTICAS", "CREAR", 8L, "Nueva practica", "admin@test.com");

        Page<AuditLogResponse> logs = auditService.listar("practicas", PageRequest.of(0, 10));

        assertThat(logs.getContent()).anyMatch(l -> l.modulo().equals("PRACTICAS"));
    }
}
