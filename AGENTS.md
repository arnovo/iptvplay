# Guía de Desarrollo para Agentes de IA (AGENTS.md)

Este documento define la arquitectura, convenciones, patrones de diseño y estándares de calidad que **todo agente de IA debe respetar** al trabajar en el código de **IPTV Play**.

---

## 🏛️ Arquitectura del Proyecto

El proyecto sigue una arquitectura desacoplada por capas:

```text
lib/
├── models/       # Entidades de dominio inmutables y serialización JSON / Map.
├── services/     # Clientes HTTP, I/O en disco, decodificadores y APIs externas.
├── providers/    # Estado reactivo mediante ChangeNotifier (Provider).
└── ui/           # Pantallas, widgets reutilizables y temas visuales.
test/
├── models_test.dart         # Pruebas unitarias de modelos de dominio.
├── m3u_parser_test.dart      # Pruebas del analizador M3U / regex VOD y series.
├── tv_focusable_test.dart    # Pruebas de widgets y navegación D-Pad en Smart TV.
├── user_activity_test.dart   # Pruebas de comportamiento reactivo y persistencia.
└── widget_test.dart          # Smoke test del arranque de la aplicación.
```

### Reglas de Dependencia entre Capas:
1. **`models/`**: No deben importar paquetes de UI ni servicios. Son clases puras de Dart con métodos `copyWith`, `toMap` / `toJson` y constructores factory como `fromXtreamJson` o `fromMap`.
2. **`services/`**: No deben importar `BuildContext` ni widgets de Flutter. Gestionan I/O en disco (`File`), red (`Dio`) o bases de datos locales (`SharedPreferences`).
3. **`providers/`**: Orquestan los servicios, exponen getters inmutables para el estado y llaman a `notifyListeners()` tras mutaciones.
4. **`ui/`**: 
   - Usar `context.watch<T>()` únicamente en el método `build()` para suscribirse a cambios de estado.
   - Usar `context.read<T>()` dentro de callbacks (`onPressed`, `onTap`, etc.).

---

## 📋 Reglas Fundamentales para Agentes

### 1. Nomenclatura e Identificadores Oficiales
- **Nombre oficial del paquete:** `iptv_play` (en `pubspec.yaml`).
- **Application ID / Bundle ID:** `com.iptvplay.app` (en Android, macOS e iOS).
- **Nombre visible:** `IPTV Play`.
- **Prohibición estricta:** No reintroducir referencias a nombres de proyectos o aplicaciones anteriores.

### 2. Soporte para Smart TV y Navegación con Mando (10-Foot UI)
Toda la interfaz debe ser 100% operable desde un sofá con un mando a distancia estándar (D-Pad):
- **Componente `TvFocusable`:** Cualquier elemento interactivo de las vistas principales (tarjetas de películas, episodios, canales, items de navegación lateral) debe estar envuelto en [TvFocusable](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/lib/ui/widgets/tv_focusable.dart).
- **Resaltado de Foco:** Debe incluir escalado suave (`1.05x`), borde cian neón (`AppTheme.primary`) y resplandor luminoso (`AppTheme.primaryGlow`).
- **Teclas de Mando:** Los escuchadores de eventos de teclado en el reproductor deben contemplar:
  - `LogicalKeyboardKey.select`, `enter`, `space`, `gameButtonA`.
  - Teclas multimedia: `mediaPlay`, `mediaPause`, `mediaPlayPause`, `mediaFastForward`, `mediaRewind`.
  - Navegación: `escape`, `goBack`, flechas direccionales.

### 3. Protocolo de Registro de Logs (`LogService`)
Toda acción relevante del sistema debe quedar registrada en el servicio centralizado de logs mediante el singleton `LogService.instance`:
- **Categorías permitidas:** `LogCategory.network`, `LogCategory.player`, `LogCategory.epg`, `LogCategory.downloads`, `LogCategory.server`, `LogCategory.system`.
- **Niveles:** `LogLevel.info`, `LogLevel.warning`, `LogLevel.error`, `LogLevel.success`.
- **Detalles técnicos:** Al capturar excepciones o errores de red, siempre pasa el mensaje o stack trace en el parámetro `details:`.

```dart
LogService.instance.error(
  LogCategory.network,
  'Fallo al descargar guía EPG',
  details: e.toString(),
);
```

### 4. Descargas Offline y Resiliencia en Caídas
- **Almacenamiento Local:** Los archivos multimedia deben guardarse en la ruta devuelta por `getApplicationDocumentsDirectory()` bajo el subdirectorio `iptv_offline/`.
- **Reanudación por HTTP Range:** Todas las descargas de archivos VOD (películas y series) deben soportar reanudación mediante la cabecera `Range: bytes=<bytes_locales>-` y escribir en modo `FileMode.append`. Nunca reinicies una descarga desde cero si el archivo parcial existe.
- **Grabaciones en Directo (PVR):** Los streams en vivo se capturan progresivamente en archivos `.ts`. Si la aplicación se cierra inesperadamente, al iniciar debe detectarse el archivo existente y marcarse automáticamente como `DownloadStatus.completed` para que el fragmento grabado sea reproducible.
- **Velocidad y ETA:** Monitorea la velocidad en ventanas de ~600ms y actualiza `speedBytesPerSecond` para alimentar la UI reactiva.

### 5. Persistencia de Preferencias del Usuario
- Configuraciones globales (ordenación seleccionada, último perfil activo, volumen por defecto, etc.) deben persistirse en `SharedPreferences` con claves prefijadas (ej. `pref_live_sort`, `pref_vod_sort`, `pref_series_sort`).
- No bloquees el hilo principal en el arranque; carga los valores guardados de manera asíncrona en el constructor o método `_init()` del provider correspondiente.

### 6. Permisos y Plataformas (macOS y Android TV)
- **macOS Entitlements:** Al añadir funcionalidades que interactúen con sockets o archivos fuera del sandbox, actualizar **AMBOS** archivos (`DebugProfile.entitlements` y `Release.entitlements`):
  - `com.apple.security.network.client`
  - `com.apple.security.network.server` (LAN stream server en puerto 8088)
  - `com.apple.security.files.user-selected.read-write` (Backups JSON)
  - `com.apple.security.files.downloads.read-write`
- **Android TV (`AndroidManifest.xml`):** Mantener siempre declarados `android.software.leanback`, `LEANBACK_LAUNCHER`, `touchscreen = false` y `usesCleartextTraffic = true` (esencial para streams HTTP IPTV).

### 7. Estilo y Buenas Prácticas de UI
- **Tema Oscuro Premium:** Toda la interfaz debe utilizar las constantes definidas en `AppTheme` (`AppTheme.background`, `AppTheme.surface`, `AppTheme.primary`, `AppTheme.accentRed`, etc.).
- **Material Ink Splash Safety:** Si envuelves un `ListTile` dentro de un `Container` o `DecoratedBox` con bordes o colores, envuélvelo siempre en `Material(color: Colors.transparent, child: ...)` para evitar la aserción de Flutter `_debugCheckHasMaterial`.
- **Diálogos Modales:** Deben tener fondo `AppTheme.surface` y bordes sutiles con `AppTheme.border`.
- **Desempeño Visual:** Usa `ListView.builder` o `ListView.separated` para colecciones grandes. Evita mapear listas completas a hijos de `Column` o `Row` con scroll.

### 8. Seguridad y Privacidad
- No incluir nunca contraseñas, credenciales, URLs privadas con tokens de autenticación ni certificados en el código fuente o repositorios.
- Mantener actualizado `.gitignore` con exclusiones para `*.env`, `*.jks`, `*.keystore`, `*.p12`, `iptv_cache/` y `iptv_offline/`.

### 9. Sincronización de Documentación
Cualquier cambio de características, plataformas soportadas o flujos de trabajo debe reflejarse en:
- [README.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/README.md) (versión en inglés)
- [README_ES.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/README_ES.md) (versión en español)
- [COMPATIBILIDAD.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/COMPATIBILIDAD.md) (matriz de soporte de hardware)
- [MANUAL_USUARIO.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/MANUAL_USUARIO.md) (guía paso a paso de uso)

---

## 🧪 Verificación Obligatoria Antes de Entregar

Antes de dar por finalizada cualquier tarea o proponer cambios al usuario, el agente **DEBE ejecutar y verificar**:

```bash
# 1. Batería de pruebas unitarias y de widgets (todos los tests deben pasar)
flutter test

# 2. Análisis estático (DEBE salir con 0 issues)
flutter analyze
```

Si `flutter test` o `flutter analyze` arrojan algún error o advertencia, corrígelo de inmediato antes de notificar al usuario.
