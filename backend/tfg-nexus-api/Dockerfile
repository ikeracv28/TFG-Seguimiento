# =========================================================================
# DOCKERFILE MULTI-ETAPA (SPRING BOOT 3.4 + JAVA 21)
# =========================================================================
# Etapa 1: Construcción (Build)
# =========================================================================
FROM maven:3.9.6-eclipse-temurin-21-alpine AS build
WORKDIR /app

COPY pom.xml .
# Cache mount para el repositorio local de Maven — reutiliza dependencias entre builds
RUN --mount=type=cache,target=/root/.m2 mvn dependency:go-offline -B

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn clean package -DskipTests

# =========================================================================
# Etapa 2: Ejecución (Runtime)
# =========================================================================
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Creamos un usuario de sistema para no ejecutar la app como root
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copiamos el JAR generado desde la etapa de construcción
COPY --from=build /app/target/*.jar app.jar

# Exponemos el puerto de la API
EXPOSE 8080

# Definimos el comando de arranque con optimizaciones para el JRE
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
