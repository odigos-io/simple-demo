FROM maven:3.8.5-openjdk-11 AS build
COPY src /home/app/src
COPY pom.xml /home/app
RUN mvn -f /home/app/pom.xml clean package

FROM eclipse-temurin:8-jre-jammy
COPY --from=build /home/app/target/*.jar /app/pricing.jar
USER 15000
CMD ["java","-jar", "/app/pricing.jar"]