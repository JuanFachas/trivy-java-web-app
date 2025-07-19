# Etapa 1: Build del proyecto
FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

RUN ./mvnw clean install -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

# Etapa 2: Escaneo (opcional, descomentarlo si se necesita)
#FROM build AS vulnscan
#COPY --from=aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
#RUN trivy rootfs --no-progress / || true

# Etapa 3: Imagen final con solo lo necesario para ejecutar
FROM eclipse-temurin:17-jre-alpine
VOLUME /tmp
ARG DEPENDENCY=/workspace/app/target/dependency

COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app

ENTRYPOINT ["java", "-Dserver.port=${PORT}", "-cp", "app:app/lib/*", "com.example.demo.DemoApplication"]
