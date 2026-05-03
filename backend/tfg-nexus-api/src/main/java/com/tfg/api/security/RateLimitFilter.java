package com.tfg.api.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Rate limiting en endpoints de autenticación: máximo 10 peticiones por minuto por IP.
 * Se ejecuta antes del filtro JWT gracias a @Order(1).
 * No requiere dependencias externas — ventana deslizante con ConcurrentHashMap.
 */
@Component
@Order(1)
public class RateLimitFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(RateLimitFilter.class);

    private static final int MAX_REQUESTS = 10;
    private static final long WINDOW_MS = 60_000L;

    // long[0] = contador de peticiones, long[1] = inicio de la ventana en ms
    private final ConcurrentHashMap<String, long[]> buckets = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {

        if (!request.getRequestURI().startsWith("/api/v1/auth/")) {
            chain.doFilter(request, response);
            return;
        }

        String ip = request.getRemoteAddr();
        long now = System.currentTimeMillis();

        long[] bucket = buckets.compute(ip, (key, existing) -> {
            if (existing == null || now - existing[1] >= WINDOW_MS) {
                return new long[]{1, now};
            }
            existing[0]++;
            return existing;
        });

        if (bucket[0] > MAX_REQUESTS) {
            log.warn("RATE_LIMIT_EXCEDIDO ip={}", ip);
            response.setStatus(429);
            response.setContentType("application/json");
            response.getWriter().write("{\"status\":429,\"message\":\"Demasiados intentos. Espera un minuto.\"}");
            return;
        }

        chain.doFilter(request, response);
    }
}
