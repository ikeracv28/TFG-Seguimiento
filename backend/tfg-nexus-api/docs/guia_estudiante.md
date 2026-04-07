# Nexus TFG - Guía de Estudio del Desarrollador (Versión Estudiante)

¡Hola! En este documento, como tu profesor, te voy a explicar "qué hace cada cosa" en tu proyecto con palabras sencillas. Piensa en esto como el mapa de tu código.

## 1. El Corazón: Las Entidades (`models.entity`)

Son las clases que representan tus tablas. Si la base de datos es el armario, las entidades son las perchas.
- **`Usuario.java`**: Es la clase más importante. Aquí guardamos quién es la persona. Tiene una relación con el Centro (un instituto) y con los Roles (lo que puede hacer).
- **`Rol.java`**: Define las etiquetas: `ROLE_ALUMNO`, `ROLE_TUTOR_CENTRO`, etc.
- **`Centro.java`**: Representa el instituto donde estudias.

**Concepto Clave:** Usamos `@Entity` para decirle a Spring: "Oye, esta clase es una tabla de mi base de datos".

## 2. Los Mensajeros: DTOs (`models.dto`)

¿Por qué no usamos la Entidad directamente en la web? Imagina que pides una pizza. El repartidor (DTO) te trae la caja (datos que necesitas), pero no te trae al pizzero ni el horno (la Entidad completa con la contraseña cifrada y datos internos).
- **`RegisterRequest.java`**: Es un `record`. Un "record" es una forma moderna de Java 21 de crear una caja de datos rápida y que no se puede cambiar por el camino (inmutable).

## 3. El Almacenero: Repositorios (`models.repository`)

Son interfaces. No escribimos código en ellas.
- **`UsuarioRepository.java`**: Gracias a Spring Data JPA, solo con escribir `findByEmail`, Spring sabe que tiene que ir a la base de datos y buscar por el correo. ¡Es magia negra tecnológica!

## 4. El Cerebro: Servicios (`services`)

Aquí es donde tomamos decisiones. El controlador recibe el golpe, pero el servicio es el que sabe boxear.
- **`AuthServiceImpl.java`**: Aquí comprobamos si el email ya existe antes de registrar a alguien. También es donde usamos el "encriptador" para que la contraseña no se vea en la base de datos.

## 5. El Vigilante: Seguridad (`security`)

Este es el bloque más difícil, pero el más seguro.
- **`JwtUtils.java`**: Es la máquina de hacer billetes (Tokens). Ella sabe crearlos y sabe detectar si son falsos.
- **`JwtAuthenticationFilter.java`**: Es el guardia de seguridad que está en la puerta. Mira cada petición que llega y dice: "¿Traes el Token? ¿Es de verdad? Pasa".
- **`UserDetailsServiceImpl.java`**: Es el que busca en el archivo de socios (la base de datos) para decirle al guardia quién eres y qué roles tienes.

## 6. El Director de Orquesta: Configuración (`config`)

- **`SecurityConfig.java`**: Es el que manda. Dice qué puertas están abiertas (Login/Registro) y qué puertas están cerradas (todo lo demás).

---

### Resumen Visual del Flujo:
1. Petición llega de Flutter -> **Vigilante** (Filtro JWT) la intercepta.
2. Si es para registrarse -> El **Director** (Config) le deja pasar directamente al **Controlador**.
3. El **Controlador** le da los datos al **Cerebro** (Servicio).
4. El **Cerebro** le pide al **Almacenero** (Repositorio) que guarde al usuario.
5. El **Almacenero** guarda la **Entidad** en PostgreSQL.

¡Espero que esta guía te ayude a entender mejor tu obra de arte!
