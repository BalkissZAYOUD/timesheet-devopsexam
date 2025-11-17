# Dockerfile
FROM openjdk:11-jdk-slim
COPY target/timesheet-devops-1.0.jar /app/timesheet-devops.jar
WORKDIR /app
ENTRYPOINT ["java", "-jar", "timesheet-devops.jar"]
