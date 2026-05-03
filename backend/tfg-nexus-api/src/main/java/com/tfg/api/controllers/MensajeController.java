package com.tfg.api.controllers;

import com.tfg.api.models.dto.MensajeRequest;
import com.tfg.api.models.dto.MensajeResponse;
import com.tfg.api.services.MensajeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/v1/mensajes")
@RequiredArgsConstructor
public class MensajeController {

    private final MensajeService mensajeService;
    private final SimpMessagingTemplate messagingTemplate;

    @GetMapping("/practica/{practicaId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TUTOR_CENTRO', 'TUTOR_EMPRESA', 'ALUMNO')")
    public ResponseEntity<List<MensajeResponse>> historial(@PathVariable Long practicaId) {
        return ResponseEntity.ok(mensajeService.listarPorPractica(practicaId));
    }

    @MessageMapping("/chat/{practicaId}")
    public void enviarMensaje(
            @DestinationVariable Long practicaId,
            @Payload MensajeRequest request,
            Principal principal) {
        if (principal == null) return;
        MensajeResponse resp = mensajeService.guardar(request, principal.getName(), practicaId);
        messagingTemplate.convertAndSend("/topic/practica/" + practicaId, resp);
    }
}
