FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/springboot-jenkins-actions-poc-1.0.0.jar app.jar
EXPOSE 8080
USER 10001
ENTRYPOINT ["java","-jar","app.jar"]
