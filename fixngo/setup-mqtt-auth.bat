@echo off
echo Generating secure password file for MQTT...
docker run --rm -v "%CD%\infrastructure\mosquitto:/mosquitto/config" eclipse-mosquitto:2.0 mosquitto_passwd -c -b /mosquitto/config/passwd fixngo_app fixngo_secure_2026
echo Done! 
echo Now restart the Mosquitto container:
echo cd infrastructure
echo docker-compose restart mosquitto
