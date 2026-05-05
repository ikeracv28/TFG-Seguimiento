package com.tfg.api.security;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.concurrent.ConcurrentHashMap;

/**
 * [A07] Blacklist de tokens JWT revocados.
 * Almacena JTI -> tiempo de expiración (ms). Un @Scheduled limpia entradas
 * ya expiradas cada hora para evitar crecimiento indefinido del mapa.
 */
@Service
public class TokenBlacklistService {

    // JTI -> expirationTimeMs
    private final ConcurrentHashMap<String, Long> blacklist = new ConcurrentHashMap<>();

    public void revocar(String jti, long expirationMs) {
        blacklist.put(jti, expirationMs);
    }

    public boolean estaRevocado(String jti) {
        return blacklist.containsKey(jti);
    }

    @Scheduled(fixedDelay = 3_600_000)
    public void limpiarExpirados() {
        long ahora = System.currentTimeMillis();
        blacklist.entrySet().removeIf(e -> e.getValue() <= ahora);
    }
}
