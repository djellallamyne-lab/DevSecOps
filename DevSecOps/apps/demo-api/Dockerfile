# syntax=docker/dockerfile:1.7
#
# Hardened multi-stage image for demo-api.
# Prefer digest pins in CI: docker build --build-arg RUNTIME_DIGEST=sha256:...
# Resolve current digests with: docker buildx imagetools inspect eclipse-temurin:21-jre-alpine

ARG JDK_IMAGE=eclipse-temurin:21-jdk-alpine
ARG JRE_IMAGE=eclipse-temurin:21-jre-alpine

# ---- build ----
FROM ${JDK_IMAGE} AS build
WORKDIR /workspace

COPY gradle/wrapper gradle/wrapper
COPY gradlew gradlew.bat build.gradle settings.gradle ./
RUN chmod +x gradlew

COPY src src
RUN ./gradlew bootJar --no-daemon -x test

# ---- runtime ----
FROM ${JRE_IMAGE}

LABEL org.opencontainers.image.title="demo-api" \
      org.opencontainers.image.description="DevSecOps lab demo API" \
      org.opencontainers.image.source="https://gitlab.com/example/devsecops"

RUN addgroup -S app && adduser -S -G app app \
    && mkdir -p /app /tmp \
    && chown -R app:app /app /tmp

WORKDIR /app
COPY --from=build --chown=app:app /workspace/build/libs/*.jar /app/app.jar

USER app
EXPOSE 8080

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom" \
    SPRING_PROFILES_ACTIVE=default

# Compatible with K8s readOnlyRootFilesystem when /tmp is mounted as emptyDir
HEALTHCHECK --interval=30s --timeout=3s --start-period=45s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/actuator/health/liveness || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
