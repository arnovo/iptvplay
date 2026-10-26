# IPTV Play (Español)

> Para la versión en inglés, consulta [README.md](README.md).

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

### 💾 10. Copias de Seguridad y Sincronización
- Exportación e importación de perfiles, favoritos, historial y progreso de reproducción en archivos `.json` mediante el selector nativo de archivos.

### 🖥️ 11. Controles Avanzados del Reproductor y Pantalla Completa
- Basado en `media_kit` (libmpv).
- Modos de relación de aspecto: *Ajustar (contain)*, *Rellenar (cover)*, *Estirar (fill)*, *16:9* y *4:3*.
- Selector de pistas de audio y subtítulos incrustados.
- Control de velocidad de reproducción (0.5x a 2.0x) y volumen.
- Pantalla completa nativa con tecla `F` / doble toque o botón en la barra superior.

---

## 🛠️ Documentos de Referencia
- 📱 [Guía de Compatibilidad](COMPATIBILIDAD.md) • [English Version](COMPATIBILITY.md)
- 📖 [Manual de Usuario](MANUAL_USUARIO.md) • [English Version](USER_MANUAL.md)
- 🤖 [Guía de Desarrollo para Agentes](AGENTS.md) • [English Version](AGENTS_EN.md)
