# Java 21 tabanlı bir görüntü seçiyoruz
FROM openjdk:21-jdk-slim

# Uygulama JAR dosyasını container'a kopyalıyoruz
COPY target/*.jar app.jar

# Uygulama portu
EXPOSE 8080

# Uygulama başlatma komutu
ENTRYPOINT ["java", "-jar", "/app.jar"]
