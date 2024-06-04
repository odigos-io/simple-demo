FROM node:20-alpine as fe-build
USER node
WORKDIR /home/node
COPY webapp/package* /home/node/
RUN yarn

COPY webapp/* /home/node/
RUN yarn build

FROM maven:3.8.5-openjdk-17 AS build
COPY src /home/app/src
COPY --from=fe-build /home/node/out/* /home/app/src/main/resources/static/
COPY pom.xml /home/app
RUN mvn -f /home/app/pom.xml clean package

FROM eclipse-temurin:17-jre-jammy
COPY --from=build /home/app/target/*.jar /app/frontend.jar
USER 15000
CMD ["java", "-jar", "/app/frontend.jar"]
