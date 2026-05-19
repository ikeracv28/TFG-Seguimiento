package com.tfg.api.models.dto;

import java.time.LocalDateTime;

public record MensajeResponse(
    Long id,
    Long practicaId,
    Long remitenteId,
    String remitenteNombre,
    String remitenteApellidos,
    String contenido,
    LocalDateTime fechaEnvio,
    String canal,
    String tipo,           // "TEXTO" | "ADJUNTO"
    String adjuntoNombre   // nombre del fichero si tipo == "ADJUNTO"
) {}
