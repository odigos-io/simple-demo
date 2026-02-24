FROM node:20-alpine AS fe-build
USER root
WORKDIR /home/node
COPY webapp/package* webapp/yarn.lock /home/node/
RUN yarn
COPY webapp /home/node/
RUN chown -R node:node /home/node
USER node
# make sure the .next directory exists and is writable
RUN mkdir -p /home/node/.next && chown -R node:node /home/node/.next
RUN yarn build

FROM maven:3.8.5-openjdk-17 AS build
COPY src /home/app/src
COPY --from=fe-build /home/node/out /home/app/src/main/resources/static
COPY pom.xml /home/app
RUN mvn -f /home/app/pom.xml --no-transfer-progress clean package

FROM eclipse-temurin:17-jre-jammy
COPY --from=build /home/app/target/*.jar /app/frontend.jar
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.10.0/opentelemetry-javaagent.jar /app/opentelemetry-javaagent.jar
ENV JAVA_TOOL_OPTIONS="-javaagent:/app/opentelemetry-javaagent.jar"
CMD ["java", "-jar", "/app/frontend.jar"]
