package com.tfg.api.config;

import com.tfg.api.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Clase de configuración de seguridad principal para el proyecto TFG-Nexus.
 * En esta clase se define la política de seguridad global de la API, configurando
 * aspectos como la autenticación basada en JWT, la protección de rutas y la gestión de sesiones.
 * Se utiliza la anotación @EnableWebSecurity para habilitar las funcionalidades de Spring Security.
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;
    private final UserDetailsService userDetailsService;

    /**
     * Define el filtro de seguridad (SecurityFilterChain) que intercepta todas las peticiones HTTP.
     * Aquí se establecen los permisos de acceso a los diferentes endpoints de la aplicación.
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Deshabilitamos CSRF (Cross-Site Request Forgery) ya que estamos desarrollando una API 
            // REST sin estado que no utiliza cookies de sesión, por lo que este tipo de ataque no es una amenaza directa.
            .csrf(AbstractHttpConfigurer::disable) 
            .authorizeHttpRequests(auth -> auth
                // Permitimos el acceso libre a los endpoints de autenticación (login y registro)
                // para que cualquier usuario pueda identificarse o darse de alta en el sistema.
                .requestMatchers("/api/v1/auth/**").permitAll() 
                // Para el resto de rutas de la API, se requiere que el usuario esté debidamente autenticado.
                .anyRequest().authenticated()
            )
            // Configuramos la gestión de sesiones como "STATELESS" (sin estado).
            // Esto es fundamental en el uso de JWT: el servidor no guarda sesiones en memoria,
            // sino que confía en el token enviado en cada petición.
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS) 
            )
            // Inyectamos nuestro proveedor de autenticación personalizado.
            .authenticationProvider(authenticationProvider())
            // Añadimos el filtro JWT antes del filtro estándar de autenticación de Spring,
            // permitiendo que validemos el token antes de intentar el acceso.
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * Configura el proveedor de autenticación. Se utiliza DaoAuthenticationProvider
     * para conectar Spring Security con nuestra base de datos a través del UserDetailsService
     * y el codificador de contraseñas.
     */
    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    /**
     * Bean para gestionar la autenticación en otros componentes del sistema.
     * Es esencial para realizar el proceso de login manual en el controlador.
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    /**
     * Definimos BCryptPasswordEncoder como el algoritmo de hashing para las contraseñas.
     * Se ha elegido BCrypt por ser un estándar de seguridad que añade un "salt" automático,
     * protegiendo las credenciales contra ataques de diccionario o tablas arcoíris.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
