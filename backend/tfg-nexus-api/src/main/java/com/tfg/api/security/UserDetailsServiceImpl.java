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
 * Servicio encargado de cargar los detalles de un usuario desde la base de datos 
 * para que Spring Security pueda realizar la autenticación.
 */
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UsuarioRepository usuarioRepository;

    /**
     * Busca un usuario por su email (username) en la base de datos.
     * 
     * @param email El correo electrónico introducido en el login.
     * @return Un objeto UserDetails que Spring Security entiende.
     * @throws UsernameNotFoundException Si el usuario no existe en la BD.
     */
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        // 1. Buscamos al usuario en nuestro repositorio.
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("Usuario no encontrado con el email: " + email));

        /**
         * 2. Convertimos nuestros Roles en GrantedAuthority.
         * Spring Security maneja los permisos mediante una lista de objetos 'GrantedAuthority'.
         * Usamos Streams de Java para transformar cada Rol (String) en un SimpleGrantedAuthority.
         */
        var authorities = usuario.getRoles().stream()
                .map(rol -> new SimpleGrantedAuthority(rol.getNombre()))
                .collect(Collectors.toList());

        /**
         * 3. Devolvemos una instancia de 'User' (implementación de UserDetails de Spring).
         * Le pasamos el email, la contraseña cifrada y la lista de roles (authorities).
         */
        return new User(
                usuario.getEmail(),
                usuario.getPasswordHash(),
                usuario.getActivo(), // Si el usuario no está activo, Spring rechazará el login.
                true, // accountNonExpired
                true, // credentialsNonExpired
                true, // accountNonLocked
                authorities
        );
    }
}
