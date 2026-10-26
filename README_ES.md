# IPTV Play (Español)

> Para la versión en inglés, consulta [README.md](README.md).

**IPTV Play** es una aplicación multiplataforma moderna, de alto rendimiento y rica en características para la reproducción y gestión de contenido IPTV (TV en Vivo, Películas VOD y Series), desarrollada en **Flutter** con el motor multimedia **MediaKit** (libmpv).

---

## 📸 Capturas de Pantalla

<div align="center">

| 🧭 Panel Principal y Navegación | 📺 Reproducción de TV en Vivo (MediaKit) |
|:---:|:---:|
| <img src="docs/screenshots/welcome_screen.png" alt="Panel Principal de IPTV Play" width="480"/> | <img src="docs/screenshots/live_player.png" alt="Reproductor de TV en Vivo IPTV Play" width="480"/> |

</div>

---

## 🌟 Características Principales

### 📺 1. TV en Vivo y Canales
- **Compatibilidad Dual:** Soporte completo para servidores **Xtream Codes API** y listas en formato **M3U / M3U8**.
- **Categorización Intuitiva:** Barra lateral con selector de categorías, conteo en tiempo real y buscador instantáneo de canales.
- **Acciones Rápidas:** Añadir a favoritos, ver guía EPG, abrir Replay TV o iniciar grabación con un solo clic.

### 🔲 2. Multiview (Pantalla Dividida hasta 4 Canales)
- Reproducción simultánea de hasta 4 canales en directo en cuadrículas 2x2 o 2x1, ideal para seguir múltiples eventos deportivos.
- Enrutamiento dinámico del foco de audio y control de volumen con el mando a distancia (D-Pad).
- Indicador luminoso de canal activo y estado en directo.

### 🎬 3. Películas (VOD) y Series
- **Catálogo Organizado:** Navegación por géneros y categorías con carátulas de alta definición.
- **Enriquecimiento con TMDB (TheMovieDatabase):** Consulta automática de sinopsis en español, puntuación comunitaria, actores y banners cinemáticos.
- **Navegador de Series:** Selector de temporadas y episodios con títulos, miniaturas e información de cada capítulo.
- **Continuar Viendo:** Detección de última posición reproducida con reanudación automática.

### 💬 4. Subtítulos Externos y Audio Dual Avanzado
- Búsqueda y descarga automática de subtítulos en línea mediante la API REST de **OpenSubtitles**.
- Carga de archivos de subtítulos locales (`.srt` y `.vtt`) desde el almacenamiento del dispositivo.
- Selector de pistas de audio con banderas por idioma e insignias de calidad (`DOLBY ATMOS`, `5.1 SURROUND`, `STEREO`).

### 🛡️ 5. Control Parental y Modo Infantil
- Protección de categorías para adultos (+18 / XXX) mediante PIN de 4 dígitos con derivación segura (SHA-256 + salt).
- Teclado numérico virtual en pantalla optimizado para mandos a distancia de Smart TV.
- Bloqueo opcional de los ajustes de la app y la gestión de listas/perfiles.

### 📅 6. Guía EPG en Cuadrícula Tradicional y Recordatorios
- Vista de línea de tiempo tradicional (formato decodificador de satélite/cable) con franjas de 30 minutos y barra visual de hora actual.
- Programación de recordatorios para emisiones futuras con servicio de avisos en tiempo real (`ReminderService`) y sintonización directa mediante el botón "VER AHORA".
- Modal interactivo con los programas pasados, actuales y futuros del canal con soporte Catch-up.
- Caché persistente en disco para carga ultrarrápida sin esperas de red.

### 🏠 7. Pantalla de Inicio "Home Hub" (Estilo Netflix / Plex)
- Carrusel destacado (Hero Banner) con las producciones más populares.
- Carril de "Continuar Viendo" con barra de progreso y minutos restantes.
- Canales favoritos con el programa que se está emitiendo en directo ahora mismo.
- Próximos recordatorios y filas horizontales con acceso directo al catálogo.

### 🎙️ 8. Búsqueda por Voz para Smart TV
- Botón de micrófono integrado en las barras de búsqueda de TV, Cine y Series.
- Diálogo flotante con animación de pulsación de voz y tarjetas de consulta rápida (Deportes, Noticias, Acción, Comedia).

### ⏪ 9. Replay TV / Catch-up (Televisión a la carta)
- Acceso a las emisiones de los últimos 7 días en canales compatibles mediante el sistema de timeshift de Xtream Codes (`get_simple_data_table`).
- Navegación día por día con reproducción directa del programa archivado.

### ⏺️ 10. Grabación PVR y Descargas Offline
- **Grabador de TV en Directo:** Captura transmisiones en vivo a archivos MPEG-TS (`.ts`) en segundo plano.
- **Descargas VOD con Reanudación (HTTP Range):** Si se interrumpe la conexión o se cierra la aplicación, la descarga se pausa y se reanuda desde los bytes existentes (`206 Partial Content`), sin reiniciar desde cero.
- **Métricas en Tiempo Real:** Visualización en vivo de la **velocidad de descarga** (ej. `3.5 MB/s`) y **tiempo estimado restante (ETA)**.
- **Controles de Descarga:** Botones para **Pausar**, **Reanudar** y **Eliminar**.
- **Persistencia en Caídas:** Si la app se cierra mientras graba, al reiniciar se finaliza automáticamente como grabación válida y reproducible.

### 📡 11. Reenvío de Video en Red Local (LAN Stream Server / Cast)
- Servidor HTTP embebido en el puerto `8088` (`http://<ip-local>:8088/stream`) con soporte CORS.
- Permite reenviar el canal o video que estás viendo para reproducirlo en Smart TVs, VLC, Kodi u otros dispositivos de la misma red local sin consumir conexiones adicionales del proveedor IPTV.

### 🔄 12. Ordenación Persistente
- Ordena canales, películas y series según tu preferencia:
  - **Canales:** Por defecto, Nombre (A-Z) o Nombre (Z-A).
  - **Películas y Series:** Por defecto, Más recientes primero (Fecha), Más antiguos, Mejor valorados (Rating), Nombre (A-Z) o Nombre (Z-A).
- **Persistencia Total:** Se guarda en `SharedPreferences` y se aplica automáticamente en cada inicio de sesión.

### ⭐ 13. Favoritos, Historial y Gestión de Recientes
- Sección de Favoritos y Canales Recientes en cada categoría.
- **Quitar de Recientes:** Botón individual `✕` en cada canal reciente y botón de **"Limpiar recientes"** en bloque.

### 📝 14. Registro de Actividad y Logs del Sistema
- Panel completo de logs accesible desde la navegación principal.
- Clasificación por niveles: **INFO**, **WARN**, **ERROR** y **OK**.
- Clasificación por áreas: **Red / IPTV**, **Reproductor**, **Guía EPG**, **Descargas / PVR**, **Servidor LAN** y **Sistema**.
- Filtros rápidos por severidad, buscador en tiempo real, visor expandible de trazas técnicas y botón para **Copiar registros** al portapapeles.

### 💾 15. Copias de Seguridad Cifradas (AES-256)
- Exportación e importación segura de perfiles, favoritos, historial y recordatorios en archivos `.json`.
- Cifrado simétrico AES-256 GCM con contraseña opcional para proteger los datos de exportación.

### 🖥️ 16. Buffer Inteligente, HUD de Estadísticas y Controles del Reproductor
- Perfiles de buffer dinámico de libmpv (`fastZapping`, `balanced`, `highResilience`) adaptables a conexiones lentas o inestables.
- HUD/OSD de estadísticas en tiempo real con tecla `I` / botón Info (bitrate, fps, códec de vídeo/audio, fotogramas perdidos y duración de caché).
- Modos de relación de aspecto: *Ajustar (contain)*, *Rellenar (cover)*, *Estirar (fill)*, *16:9* y *4:3*.
- Pantalla completa nativa con tecla `F` / doble toque o botón en la barra superior.

### ⚙️ 17. Panel Unificado de Configuración y Menús Colapsables
- **Centro de Configuración Centralizado:** Gestión integral de listas y perfiles, control parental con PIN, visor de logs, copias de seguridad AES-256, cambio de idioma y perfil de buffer de reproducción en una única vista organizada.
- **Menú Lateral y Submenú Colapsables:** Opción de ocultar/mostrar tanto la barra de navegación izquierda como la barra de subcategorías con un toque o botón de mando a distancia, maximizando el espacio de visualización de canales, películas y series.

---

## 🔒 Privacidad y Seguridad

* **Privacidad 100% Local:** Listas de reproducción, credenciales, bases de datos EPG y vídeos descargados se conservan localmente en el dispositivo. Cero telemetría y sin envío de datos a servicios analíticos externos.
* **Almacenamiento Cifrado de Credenciales (Keystore / Keychain):** Cifrado seguro de credenciales sensibles (como contraseñas del panel Xtream) empleando almacenamiento protegido por hardware (`flutter_secure_storage` mediante Apple Keychain y Android Keystore) en lugar de almacenamiento plano sin cifrar.
* **Sanitización Estricta de URLs y Protección Anti-SSRF:** Validación rigurosa de que las URLs comiencen exclusivamente por `http://` o `https://` (rechazando esquemas no seguros como `file://`, `javascript://` o `content://`), con bloqueo proactivo de redirecciones maliciosas hacia IPs locales o de loopback (`localhost`, `127.0.0.1`, `::1`) desde el cliente HTTP.
* **Sandbox Seguro:** Entitlements del sandbox de macOS que restringen estrictamente el acceso a sockets de red y archivos seleccionados por el usuario.

---

## 🛠️ Documentos de Referencia
- 📱 [Guía de Compatibilidad](COMPATIBILIDAD.md) • [English Version](COMPATIBILITY.md)
- 📖 [Manual de Usuario](MANUAL_USUARIO.md) • [English Version](USER_MANUAL.md)
- 🤖 [Guía de Desarrollo para Agentes](AGENTS.md) • [English Version](AGENTS_EN.md)
