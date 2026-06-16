# Guía de Conectividad y Configuración de Red para el Módulo Móvil (Flutter)

Este módulo de Flutter se conecta con el backend de Spring Boot (ejecutado por defecto en el puerto `8081`). Dependiendo del entorno de pruebas en el que ejecutes tu aplicación móvil, la URL base del API (`API_BASE_URL`) debe configurarse de forma distinta para superar las barreras de red física y virtual.

---

## 1. Configuración de la URL según el Entorno de Ejecución

El archivo encargado de resolver la URL base es [api_client.dart](file:///c:/EDBERTO/ULT%20SEMESTRE/SW1/1ER%20parcial/SW1_PN_1_2026/politica_negocio_movil/lib/core/network/api_client.dart) en el método `_resolveBaseUrl()`. Las configuraciones recomendadas son las siguientes:

### A. PC / Navegador Web / Desktop (Local)
* **URL a utilizar:** `http://localhost:8081/api/`
* **Por qué:** Dado que la app y el backend se ejecutan en el mismo sistema operativo de tu PC, el alias `localhost` hace referencia a tu propia máquina de forma directa.
* **Protocolo:** `http` (Desarrollo local).

### B. Emulador de Android (AVD)
* **URL a utilizar:** `http://10.0.2.2:8081/api/`
* **Por qué:** El emulador corre en una máquina virtual con su propio stack de red aislado. Si utilizas `localhost` dentro del emulador, este intentará buscar el backend *dentro del propio emulador*, lo cual fallará. Android asigna la IP especial **`10.0.2.2`** como un puente virtual hacia el `localhost` de tu computadora anfitriona.
* **Protocolo:** `http` (Desarrollo local).

### C. Dispositivo Móvil Físico en Red Local (Misma WiFi)
* **URL a utilizar:** `http://<IP_PRIVADA_DE_TU_PC>:8081/api/` (Ejemplo: `http://192.168.1.50:8081/api/`)
* **Por qué:** Tu dispositivo móvil y tu PC están en la misma red de tu router doméstico. Al indicarle la IP privada clase C de tu PC, el móvil puede ubicar el servidor Spring Boot en la red de área local (LAN).
* **Requisito:** Ambos dispositivos deben estar conectados exactamente a la misma red WiFi y el Firewall de tu PC debe permitir conexiones entrantes en el puerto `8081`.
* **Protocolo:** `http` (Desarrollo local).

### D. Dispositivo Móvil Físico Exterior (Datos Móviles 4G/5G o WiFi Externa)
* **URL a utilizar:** URL pública en Internet mediante un Túnel (ej. Tunnelmole / Ngrok) o Despliegue Cloud (AWS / Heroku).
  * *Ejemplo Tunnelmole:* `https://xxxxxx.tunnelmole.net/api/`
* **Por qué:** Cuando el teléfono móvil se encuentra fuera de tu red WiFi local, **las IPs privadas (como `192.168.x.x` o `10.0.2.2`) son inaccesibles**. El tráfico debe pasar obligatoriamente a través de internet. Tunnelmole expone tu puerto local `8081` a un servidor intermedio seguro en la nube para que sea visible en cualquier parte del mundo.
* **Protocolo:** `https` (Cifrado y público).

---

## 2. Consideraciones Importantes sobre HTTP vs HTTPS

### Uso de HTTP (Texto Claro)
* **Cuándo usarlo:** Únicamente para desarrollo local en emuladores (`10.0.2.2`) o pruebas controladas en tu red WiFi local (`192.168.x.x`).
* **Seguridad de Android (Crítico):** A partir de Android 9 (API 28), el sistema operativo bloquea de forma nativa cualquier petición HTTP de texto claro sin cifrar por motivos de seguridad. 
  * Para permitir el desarrollo local con HTTP, es **obligatorio** que el archivo [AndroidManifest.xml](file:///c:/EDBERTO/ULT%20SEMESTRE/SW1/1ER%20parcial/SW1_PN_1_2026/politica_negocio_movil/android/app/src/main/AndroidManifest.xml) cuente con la propiedad `android:usesCleartextTraffic="true"` dentro de la etiqueta `<application>`:
    ```xml
    <application
        ...
        android:usesCleartextTraffic="true">
    ```

### Uso de HTTPS (Cifrado de Capa de Conexión)
* **Cuándo usarlo:** Obligatorio para producción, despliegues en la nube (AWS) y cuando se expone el servidor local mediante túneles públicos (`tunnelmole` o `ngrok`).
* **Seguridad:** Cifra los datos transmitidos (evitando ataques de espionaje o interceptación de contraseñas por terceros en redes públicas).
* **Certificados SSL en Desarrollo:** Si utilizas túneles o servidores con certificados autofirmados o no reconocidos por el sistema operativo de tu teléfono, la librería `Dio` arrojará un error de seguridad de confianza. En `api_client.dart` tenemos configurada la propiedad `badCertificateCallback` para ignorar estas validaciones en entornos de pruebas:
  ```dart
  client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  ```

---

## 3. Checklist para Resolver Problemas de Conexión

1. **¿El backend Spring Boot está encendido?**
   Asegúrate de ejecutar `.\mvnw.cmd spring-boot:run` en la carpeta `politica-negocio` y verificar que no haya errores de inicio.
2. **¿La URL base termina con barra diagonal `/`?**
   La constante configurada en Flutter debe terminar en `/api/`. Si falta la barra final, Dio descartará el segmento `/api` al resolver rutas relativas (ej. llamará a `/health` en vez de `/api/health`), produciendo errores **401** o **404**.
3. **¿Hiciste un Hot Restart o reinstalaste la app?**
   Si realizas cambios en `api_client.dart` pero la consola de Flutter perdió la conexión con el celular físico o emulador, el Hot Reload **no** funcionará. Debes reconectar el dispositivo y volver a correr `flutter run` para compilar la aplicación con la nueva URL.
