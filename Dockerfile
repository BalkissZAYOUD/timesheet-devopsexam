# Dockerfile
FROM eclipse-temurin:11-jdk
COPY target/timesheet-devops-1.0.jar /app/timesheet-devops.jar
WORKDIR /app
CMD ["java", "-jar", "timesheet-devops.jar"]
