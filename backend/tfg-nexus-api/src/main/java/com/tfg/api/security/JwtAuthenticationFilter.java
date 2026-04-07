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

import java.io.IOException;

/**
 * Filtro personalizado de autenticación que intercepta cada petición HTTP que llega a la API.
 * Esta clase extiende de OncePerRequestFilter para garantizar que el filtro se ejecute
 * exactamente una vez por cada solicitud realizada por el cliente.
 * Su función principal es validar la presencia y validez del token JWT enviado por el usuario.
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtils jwtUtils;
    private final UserDetailsService userDetailsService;

    /**
     * Lógica principal del filtro que analiza la cabecera 'Authorization' para extraer el JWT.
     * Si el token es válido, establece la autenticación en el contexto de seguridad de Spring.
     */
    @Override
    protected void doFilterInternal(
            HttpServletRequest request, 
            HttpServletResponse response, 
            FilterChain filterChain
    ) throws ServletException, IOException {
        
        // Obtenemos la cabecera de autorización de la solicitud HTTP entrante.
        final String authHeader = request.getHeader("Authorization");
        final String jwt;
        final String userEmail;

        // Según el estándar, el token debe ir precedido por la cadena "Bearer ".
        // Si no se encuentra la cabecera o no empieza correctamente, permitimos que la petición
        // siga su curso, aunque probablemente sea rechazada por Spring Security si la ruta requiere permisos.
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // El token empieza después de "Bearer " (7 caracteres: B-e-a-r-e-r-espacio).
        jwt = authHeader.substring(7);
        // Utilizamos nuestra utilidad JwtUtils para extraer el email del usuario (subject) contenido en el token.
        userEmail = jwtUtils.extractUsername(jwt);

        // Verificamos si hemos obtenido un email y si el usuario no tiene una autenticación ya establecida
        // en el contexto actual de seguridad de Spring (evitamos procesar tokens si ya está autenticado).
        if (userEmail != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            // Cargamos los detalles del usuario desde la base de datos (UserDetails).
            UserDetails userDetails = this.userDetailsService.loadUserByUsername(userEmail);

            // Realizamos la validación técnica del token (firma, fecha de expiración y correspondencia de usuario).
            if (jwtUtils.validateToken(jwt, userDetails)) {
                // Si la validación es correcta, creamos el objeto de autenticación necesario para Spring Security.
                UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                        userDetails,
                        null,
                        userDetails.getAuthorities()
                );
                
                // Asociamos detalles adicionales de la petición web al objeto de autenticación.
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                // Finalmente, guardamos la autenticación en el SecurityContextHolder, permitiendo que
                // el sistema reconozca al usuario para las peticiones posteriores dentro de este ciclo de vida.
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        // Continuamos con el resto de filtros de la cadena (por ejemplo, el filtro de autorización).
        filterChain.doFilter(request, response);
    }
}
