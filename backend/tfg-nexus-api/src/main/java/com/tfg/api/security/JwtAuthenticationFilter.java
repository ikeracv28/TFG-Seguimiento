package com.tfg.api.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import io.jsonwebtoken.JwtException;

import java.io.IOException;

/**
 * Filtro que intercepta cada petición HTTP para validar el token JWT.
 * Hereda de OncePerRequestFilter para asegurar que se ejecute una sola vez por petición.
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtils jwtUtils;
    private final UserDetailsService userDetailsService;
    private final TokenBlacklistService tokenBlacklistService;

    /**
     * Lógica principal del filtro.
     */
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        // 1. Obtener la cabecera 'Authorization'
        final String authHeader = request.getHeader("Authorization");

        // 2. Si no hay cabecera o no empieza por 'Bearer ', seguimos con el siguiente filtro
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            // 3. Extraer el token (quitando la palabra 'Bearer ')
            final String jwt = authHeader.substring(7);

            // 4. Extraer el email del usuario usando nuestra utilidad JWT
            final String userEmail = jwtUtils.extractUsername(jwt);

            // 5. Si hay email, el token no está revocado y el usuario no está autenticado
            String jti = jwtUtils.extractJti(jwt);
            if (userEmail != null
                    && !tokenBlacklistService.estaRevocado(jti)
                    && SecurityContextHolder.getContext().getAuthentication() == null) {

                // Cargamos los detalles del usuario desde la BD
                UserDetails userDetails = this.userDetailsService.loadUserByUsername(userEmail);

                // 6. Si el token es válido, creamos el objeto de autenticación
                if (jwtUtils.validateToken(jwt, userDetails)) {
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userDetails,
                            null,
                            userDetails.getAuthorities()
                    );

                    // Añadimos detalles de la petición original
                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    // 7. Establecemos al usuario como autenticado en el sistema
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            }
        } catch (JwtException e) {
            // Token inválido o caducado: no autenticamos al usuario y continuamos.
            // Spring Security denegará el acceso si el endpoint lo requiere.
            SecurityContextHolder.clearContext();
        }

        // 8. Continuamos con la cadena de filtros (ir al controlador u otros filtros)
        filterChain.doFilter(request, response);
    }
}
