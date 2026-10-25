# IPTV Play

**IPTV Play** es una aplicación multiplataforma moderna, de alto rendimiento y rica en características para la reproducción y gestión de contenido IPTV (TV en Vivo, Películas VOD y Series), desarrollada en **Flutter** con el motor multimedia **MediaKit** (libmpv).

---

## 🌟 Características Principales

### 📺 1. TV en Vivo y Canales
- **Compatibilidad Dual:** Soporte completo para servidores **Xtream Codes API** y listas en formato **M3U / M3U8**.
- **Categorización Intuitiva:** Barra lateral con selector de categorías, conteo en tiempo real y buscador instantáneo de canales.
- **Acciones Rápidas:** Añadir a favoritos, ver guía EPG, abrir Replay TV o iniciar grabación con un solo clic.

### 🎬 2. Películas (VOD) y Series
- **Catálogo Organizado:** Navegación por géneros y categorías con carátulas de alta definición.
- **Enriquecimiento con TMDB (TheMovieDatabase):** Consulta automática de sinopsis en español, puntuación comunitaria, actores y banners cinemáticos.
- **Navegador de Series:** Selector de temporadas y episodios con títulos, miniaturas e información de cada capítulo.
- **Continuar Viendo:** Detección de última posición reproducida con reanudación automática.

### 📅 3. Guía Electrónica de Programas (EPG / XMLTV)
- **Descarga y Descompresión:** Parser nativo para fuentes XMLTV en formato directo o comprimido (`.xml.gz`).
- **Línea de Tiempo en Vivo:** Barra de progreso visual y programa en emisión actual en la lista de canales.
- **Programación Completa:** Modal interactivo con los programas pasados, actuales y futuros del canal.
- **Caché Persistente:** Almacenamiento local en disco para arranque instantáneo sin esperas de red.

### ⏪ 4. Replay TV / Catch-up (Televisión a la carta)
- Acceso a las emisiones de los últimos 7 días en canales compatibles mediante el sistema de timeshift de Xtream Codes (`get_simple_data_table`).
- Navegación día por día con reproducción directa del programa archivado.

### ⏺️ 5. Grabación PVR y Descargas Offline
- **Grabador de TV en Directo:** Captura transmisiones en vivo a archivos MPEG-TS (`.ts`) en segundo plano.
- **Descargas VOD con Reanudación (HTTP Range):** Si se interrumpe la conexión o se cierra la aplicación, la descarga se pausa y se reanuda desde los bytes existentes (`206 Partial Content`), sin reiniciar desde cero.
- **Métricas en Tiempo Real:** Visualización en vivo de la **velocidad de descarga** (ej. `3.5 MB/s`) y **tiempo estimado restante (ETA)**.
- **Controles de Descarga:** Botones para **Pausar**, **Reanudar** y **Eliminar**.
- **Persistencia en Caídas:** Si la app se cierra mientras graba, al reiniciar se finaliza automáticamente como grabación válida y reproducible.

### 📡 6. Reenvío de Video en Red Local (LAN Stream Server / Cast)
- Servidor HTTP embebido en el puerto `8088` (`http://<ip-local>:8088/stream`) con soporte CORS.
- Permite reenviar el canal o video que estás viendo para reproducirlo en Smart TVs, VLC, Kodi u otros dispositivos de la misma red local sin consumir conexiones adicionales del proveedor IPTV.

### 🔄 7. Ordenación Persistente
- Ordena canales, películas y series según tu preferencia:
  - **Canales:** Por defecto, Nombre (A-Z) o Nombre (Z-A).
  - **Películas y Series:** Por defecto, Más recientes primero (Fecha), Más antiguos, Mejor valorados (Rating), Nombre (A-Z) o Nombre (Z-A).
- **Persistencia Total:** Se guarda en `SharedPreferences` y se aplica automáticamente en cada inicio de sesión.

### ⭐ 8. Favoritos, Historial y Gestión de Recientes
- Sección de Favoritos y Canales Recientes en cada categoría.
- **Quitar de Recientes:** Botón individual `✕` en cada canal reciente y botón de **"Limpiar recientes"** en bloque.

### 📝 9. Registro de Actividad y Logs del Sistema
- Panel completo de logs accesible desde la navegación principal.
- Clasificación por niveles: **INFO**, **WARN**, **ERROR** y **OK**.
- Clasificación por áreas: **Red / IPTV**, **Reproductor**, **Guía EPG**, **Descargas / PVR**, **Servidor LAN** y **Sistema**.
- Filtros rápidos por severidad, buscador en tiempo real, visor expandible de trazas técnicas y botón para **Copiar registros** al portapapeles.
- Persistencia local automática en `iptv_cache/system_logs.json`.

### 💾 10. Copias de Seguridad y Sincronización
- Exportación e importación de perfiles, favoritos, historial y progreso de reproducción en archivos `.json` mediante el selector nativo de archivos.

### 🖥️ 11. Controles Avanzados del Reproductor y Pantalla Completa
- Basado en `media_kit` (libmpv).
- Modos de relación de aspecto: *Ajustar (contain)*, *Rellenar (cover)*, *Estirar (fill)*, *16:9* y *4:3*.
- Selector de pistas de audio y subtítulos incrustados.
- Control de velocidad de reproducción (0.5x a 2.0x) y volumen.
- Pantalla completa nativa con tecla `F` / doble toque o botón en la barra superior.

---

## 🛠️ Tecnologías y Arquitectura

- **Framework:** Flutter 3.x (Dart 3.x)
- **Motor Multimedia:** `media_kit`, `media_kit_video`, `media_kit_libs_macos_video` (libmpv)
- **Gestión de Estado:** `provider` (`MultiProvider`, `ChangeNotifier`)
- **Red y HTTP:** `dio` con soporte de streaming y headers de rango
- **Almacenamiento Local:** `shared_preferences`, `path_provider`
- **Gestión de Ventana Desktop:** `window_manager`
- **Manipulación XML:** `xml`

### Estructura del Código

```text
lib/
├── main.dart                       # Punto de entrada y registro de MultiProvider
├── models/                         # Modelos de datos y serialización JSON
│   ├── app_log.dart                # Registro de logs del sistema
│   ├── catchup_item.dart           # Programas de Replay TV
│   ├── channel.dart                # Canales en vivo
│   ├── download_item.dart          # Grabaciones y descargas offline
│   ├── epg_program.dart            # Guía EPG y horarios
│   ├── playback_progress.dart      # Posición de continuar viendo
│   ├── playlist_profile.dart       # Perfiles Xtream / M3U
│   ├── series_item.dart            # Series y episodios
│   ├── sort_option.dart            # Opciones de ordenación persistente
│   └── vod_item.dart               # Películas VOD
├── providers/                      # Lógica de estado reactiva (ChangeNotifier)
│   ├── catalog_provider.dart       # Catálogo, filtrado y ordenación
│   ├── download_provider.dart      # Descargas, velocidad, pausa y reanudación
│   ├── epg_provider.dart           # Sincronización de guía EPG
│   ├── log_provider.dart           # Registro de actividad y estadísticas
│   ├── profile_provider.dart       # Gestión de perfiles IPTV
│   ├── stream_server_provider.dart # Servidor de streaming local en LAN
│   └── user_activity_provider.dart # Favoritos, recientes e historial
├── services/                       # Servicios de red, disco y utilidades
│   ├── backup_service.dart         # Exportación / importación JSON
│   ├── catchup_service.dart        # API de Replay TV Xtream
│   ├── download_service.dart       # Descargas con HTTP Range y grabaciones TS
│   ├── epg_service.dart            # Parser XMLTV y GZip
│   ├── iptv_repository.dart        # Repositorio de listas y caché en disco
│   ├── local_stream_server.dart    # Servidor HTTP LAN proxy
│   ├── log_service.dart            # Buffer y persistencia de logs
│   ├── tmdb_service.dart           # Metadatos y carátulas TMDB
│   ├── user_activity_service.dart  # Persistencia de favoritos y recientes
│   └── xtream_client.dart          # Cliente HTTP Xtream Codes
└── ui/                             # Interfaz gráfica y diseño
    ├── screens/                    # Pantallas principales
    │   ├── home_shell_screen.dart  # Shell con sidebar y navegación
    │   ├── live_tv_screen.dart     # Canales en vivo
    │   ├── vod_screen.dart         # Películas
    │   ├── series_screen.dart      # Series
    │   ├── downloads_screen.dart   # Descargas y grabaciones offline
    │   ├── logs_screen.dart        # Registro de logs del sistema
    │   ├── player_screen.dart      # Reproductor avanzado de video
    │   └── profile_list_screen.dart# Gestión de perfiles IPTV
    ├── theme/                      # Paleta de colores y estilos oscuros
    └── widgets/                    # Componentes reutilizables
```

---

## 🚀 Instalación y Puesta en Marcha

### Requisitos Previos
- **Flutter SDK:** ^3.13.1 o superior.
- **macOS:** Xcode instalado con soporte de CocoaPods (para compilación macOS).

### 1. Clonar y obtener dependencias
```bash
git clone <url-del-repositorio>
cd iptvexp
flutter pub get
```

### 2. Configurar permisos en macOS (si aplica)
Los permisos de red entrante/saliente y sistema de archivos ya están configurados en:
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

Incluyen:
- `com.apple.security.network.client`
- `com.apple.security.network.server` (para reenvío en LAN)
- `com.apple.security.files.user-selected.read-write` (para copias de seguridad)
- `com.apple.security.files.downloads.read-write`

### 3. Ejecutar en desarrollo
```bash
# Ejecutar en macOS Desktop
flutter run -d macos

# O verificar análisis de código y tests
flutter analyze
flutter test
```

---

## 🔒 Privacidad y Almacenamiento Local
Toda la información (credenciales de servidor, listas M3U, carátulas, registros de logs, programas EPG y descargas) se almacena **exclusivamente de forma local** en el dispositivo del usuario (`getApplicationDocumentsDirectory()` / `SharedPreferences`). No se envía ningún dato a servidores de terceros que no sean el propio proveedor IPTV configurado por el usuario o la API pública de TMDB para metadatos.
