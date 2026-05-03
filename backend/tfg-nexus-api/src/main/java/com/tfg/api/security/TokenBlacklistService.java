package com.tfg.api.security;

import org.springframework.stereotype.Service;

import java.util.concurrent.ConcurrentHashMap;

/**
 * [A07] Blacklist de tokens JWT revocados.
 *
 * Almacena los JTI (JWT ID) de tokens que han sido invalidados mediante logout.
 * Al ser in-memory, la blacklist se pierde al reiniciar el servidor — los tokens
 * en circulación quedan inválidos de facto porque caducan solos (expiration).
 * Para producción real se reemplazaría por Redis con TTL igual al expiration del JWT.
 */
@Service
public class TokenBlacklistService {

    private final ConcurrentHashMap<String, Boolean> blacklist = new ConcurrentHashMap<>();

    public void revocar(String jti) {
        blacklist.put(jti, Boolean.TRUE);
    }

    public boolean estaRevocado(String jti) {
        return blacklist.containsKey(jti);
    }
}
