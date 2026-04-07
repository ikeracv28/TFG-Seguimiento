package com.tfg.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Clase principal de entrada para la aplicación Spring Boot. 
 * Configura el arranque automático, el escaneo de componentes y la configuración del framework.
 */
@SpringBootApplication
public class TfgApiApplication {

    public static void main(String[] args) {
        // Ejecución de la aplicación y arranque del servidor embebido.
        SpringApplication.run(TfgApiApplication.class, args);
    }
}
