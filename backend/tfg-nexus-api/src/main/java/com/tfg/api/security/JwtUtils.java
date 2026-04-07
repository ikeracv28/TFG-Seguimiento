package com.tfg.api.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

/**
 * Clase de utilidad encargada de la gestión técnica de los tokens JSON Web Token (JWT).
 * En este componente centralizamos todas las operaciones necesarias para emitir, validar 
 * y extraer información de los tokens de autenticación de la aplicación.
 * Para implementar estas funcionalidades, se utiliza la librería oficial 'jjwt' (Java JWT).
 */
@Component
public class JwtUtils {

    // Se define una clave secreta para la firma digital de los tokens.
    // En un entorno de producción real, este valor debería estar almacenado en variables de entorno 
    // o un servicio de gestión de secretos para evitar exponerlo en el código fuente.
    @Value("${jwt.secret:clave_secreta_muy_larga_y_segura_para_el_proyecto_nexus_tfg_2026}")
    private String secret;

    // Tiempo de vida del token expresado en milisegundos (ej: 86400000 ms equivale a 24 horas).
    @Value("${jwt.expiration:86400000}")
    private Long expiration;

    /**
     * Genera un nuevo token JWT a partir de los detalles de un usuario autenticado.
     */
    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        return createToken(claims, userDetails.getUsername());
    }

    /**
     * Construye el token JWT utilizando el patrón Builder de jjwt.
     * @param claims Metadatos adicionales que deseamos incluir en el token.
     * @param subject El identificador principal del usuario (en este caso, su email).
     */
    private String createToken(Map<String, Object> claims, String subject) {
        return Jwts.builder()
                .claims(claims) // Atributos personalizados del token.
                .subject(subject) // Establecemos el usuario al que pertenece el token.
                .issuedAt(new Date(System.currentTimeMillis())) // Fecha de emisión.
                .expiration(new Date(System.currentTimeMillis() + expiration)) // Fecha de caducidad.
                .signWith(getSigningKey()) // Firmamos digitalmente con nuestra clave HS256.
                .compact(); // Finalizamos la construcción y generamos el string del token.
    }

    /**
     * Valida si un token es correcto comparando el usuario extraído con los detalles de la BD
     * y comprobando que el token no haya expirado.
     */
    public Boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

    /**
     * Recupera el nombre de usuario (subject) guardado dentro del token JWT.
     */
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    /**
     * Obtiene la fecha de expiración almacenada en el token.
     */
    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    /**
     * Método genérico para extraer cualquier tipo de "claim" (atributo) del token
     * utilizando una función de resolución.
     */
    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    /**
     * Procesa el token completo para extraer todas sus declaraciones (Claims).
     * Este proceso requiere verificar la firma digital con la clave secreta.
     */
    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Comprueba de forma sencilla si la fecha actual es posterior a la fecha de expiración del token.
     */
    private Boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    /**
     * Genera una clave de firma HMAC segura a partir del string secreto configurado.
     */
    private SecretKey getSigningKey() {
        byte[] keyBytes = secret.getBytes();
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
