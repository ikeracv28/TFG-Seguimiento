package com.tfg.api.security;

import com.tfg.api.models.entity.Usuario;
import com.tfg.api.models.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.stream.Collectors;

/**
 * Implementación personalizada del servicio UserDetailsService de Spring Security.
 * Esta clase es fundamental en el proceso de autenticación, ya que actúa como puente
 * entre nuestra base de datos (donde almacenamos los usuarios del sistema) y el 
 * motor de seguridad de Spring.
 */
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UsuarioRepository usuarioRepository;

    /**
     * Busca los detalles de un usuario en la base de datos basándose en su email.
     * Este método es invocado automáticamente por Spring Security durante el login.
     * 
     * @param email Identificador único del usuario (en este proyecto usamos el correo).
     * @return Una instancia de UserDetails compatible con el sistema de seguridad.
     * @throws UsernameNotFoundException Si no se encuentra el correo en el repositorio.
     */
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        // Paso 1: Consultamos nuestro repositorio para recuperar la entidad 'Usuario'.
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("No se ha encontrado ningún usuario con el email: " + email));

        /**
         * Paso 2: Conversión de roles a autoridades (Authorities).
         * Spring Security no entiende directamente nuestras entidades de Rol.
         * Por ello, transformamos cada objeto Rol en un objeto SimpleGrantedAuthority,
         * que es el estándar que utiliza el framework para gestionar los permisos.
         */
        var authorities = usuario.getRoles().stream()
                .map(rol -> new SimpleGrantedAuthority(rol.getNombre()))
                .collect(Collectors.toList());

        /**
         * Paso 3: Construcción del objeto User de Spring Security.
         * Devolvemos una implementación oficial de UserDetails, pasándole:
         * - El email como nombre de usuario.
         * - La contraseña (hash) para que Spring la compare con la introducida.
         * - El estado 'activo' del usuario para permitir o denegar el acceso.
         * - La lista de autoridades que acabamos de generar.
         */
        return new User(
                usuario.getEmail(),
                usuario.getPasswordHash(),
                usuario.getActivo(), // Si el usuario está desactivado, el login fallará automáticamente.
                true, // Indica que la cuenta no ha expirado.
                true, // Indica que las credenciales no han expirado.
                true, // Indica que la cuenta no está bloqueada.
                authorities
        );
    }
}
