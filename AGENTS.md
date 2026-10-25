# Guía de Desarrollo para Agentes de IA (AGENTS.md)

Este documento define la arquitectura, convenciones, patrones de diseño y estándares de calidad que **todo agente de IA debe respetar** al trabajar en el código de **IPTV Expert**.

---

## 🏛️ Arquitectura del Proyecto

El proyecto sigue una arquitectura desacoplada por capas:

```text
lib/
├── models/       # Entidades de dominio inmutables y serialización JSON.
├── services/     # Clientes HTTP, I/O en disco, decodificadores y APIs externas.
├── providers/    # Estado reactivo mediante ChangeNotifier (Provider).
└── ui/           # Pantallas, widgets reutilizables y temas visuales.
```

### Reglas de Dependencia entre Capas:
1. **`models/`**: No deben importar paquetes de UI ni servicios. Son clases puras de Dart con métodos `copyWith`, `toJson` y `fromJson`.
2. **`services/`**: No deben importar `BuildContext` ni widgets de Flutter. Gestionan I/O en disco (`File`), red (`Dio`) o bases de datos locales (`SharedPreferences`).
3. **`providers/`**: Orquestan los servicios, exponen getters inmutables para el estado y llaman a `notifyListeners()` tras mutaciones.
4. **`ui/`**: 
   - Usar `context.watch<T>()` únicamente en el método `build()` para suscribirse a cambios de estado.
   - Usar `context.read<T>()` dentro de callbacks (`onPressed`, `onTap`, etc.).

---

## 📋 Reglas Fundamentales para Agentes

### 1. Protocolo de Registro de Logs (`LogService`)
Toda acción relevante del sistema debe quedar registrada en el servicio centralizado de logs mediante el singleton `LogService.instance`:
- **Categorías permitidas:** `LogCategory.network`, `LogCategory.player`, `LogCategory.epg`, `LogCategory.downloads`, `LogCategory.server`, `LogCategory.system`.
- **Niveles:** `LogLevel.info`, `LogLevel.warning`, `LogLevel.error`, `LogLevel.success`.
- **Detalles técnicos:** Al capturar excepciones o errores de red, siempre pasa el mensaje o stack trace en el parámetro `details:`.

```dart
// Ejemplo:
LogService.instance.error(
  LogCategory.network,
  'Fallo al descargar guía EPG',
  details: e.toString(),
);
```

### 2. Descargas Offline y Resiliencia en Caídas
- **Almacenamiento Local:** Los archivos multimedia deben guardarse en la ruta devuelta por `getApplicationDocumentsDirectory()` bajo el subdirectorio `iptv_offline/`.
- **Reanudación por HTTP Range:** Todas las descargas de archivos VOD (películas y series) deben soportar reanudación mediante la cabecera `Range: bytes=<bytes_locales>-` y escribir en modo `FileMode.append`. Nunca reinicies una descarga desde cero si el archivo parcial existe.
- **Grabaciones en Directo (PVR):** Los streams en vivo se capturan progresivamente en archivos `.ts`. Si la aplicación se cierra inesperadamente, al iniciar debe detectarse el archivo existente y marcarse automáticamente como `DownloadStatus.completed` para que el fragmento grabado sea reproducible.
- **Velocidad y ETA:** Monitorea la velocidad en ventanas de ~600ms y actualiza `speedBytesPerSecond` para alimentar la UI reactiva.

### 3. Persistencia de Preferencias del Usuario
- Configuraciones globales (ordenación seleccionada, último perfil activo, volumen por defecto, etc.) deben persistirse en `SharedPreferences` con claves prefijadas (ej. `pref_live_sort`, `pref_vod_sort`, `pref_series_sort`).
- No bloquees el hilo principal en el arranque; carga los valores guardados de manera asíncrona en el constructor o método `_init()` del provider correspondiente.

### 4. Permisos y Entitlements en macOS
Si añades una funcionalidad que interactúe con el sistema operativo de escritorio (sockets de red, servidor HTTP local, acceso a archivos fuera del sandbox):
- **OBLIGATORIO:** Actualizar **AMBOS** archivos de entitlements en macOS:
  1. `macos/Runner/DebugProfile.entitlements`
  2. `macos/Runner/Release.entitlements`
- Entitlements actualmente activos:
  - `com.apple.security.network.client`: Conexiones salientes a servidores IPTV.
  - `com.apple.security.network.server`: Servidor HTTP proxy LAN en puerto 8088.
  - `com.apple.security.files.user-selected.read-write`: Guardar/cargar backups JSON con `file_picker`.
  - `com.apple.security.files.downloads.read-write`: Carpeta de descargas del usuario.

### 5. Estilo y Buenas Prácticas de UI
- **Tema Oscuro Premium:** Toda la interfaz debe utilizar las constantes definidas en `AppTheme` (`AppTheme.background`, `AppTheme.surface`, `AppTheme.primary`, `AppTheme.accentRed`, etc.).
- **Material Ink Splash Safety:** Si envuelves un `ListTile` dentro de un `Container` o `DecoratedBox` con bordes o colores, envuélvelo siempre en `Material(color: Colors.transparent, child: ...)` para evitar la aserción de Flutter `_debugCheckHasMaterial`.
- **Diálogos Modales:** Deben tener fondo `AppTheme.surface` y bordes sutiles con `AppTheme.border`.
- **Desempeño Visual:** Usa `ListView.builder` o `ListView.separated` para colecciones grandes. Evita mapear listas completas a hijos de `Column` o `Row` con scroll.

---

## 🧪 Verificación Obligatoria Antes de Entregar

Antes de dar por finalizada cualquier tarea o proponer cambios al usuario, el agente **DEBE ejecutar y verificar**:

```bash
# 1. Análisis estático (DEBE salir con 0 issues)
flutter analyze

# 2. Batería de pruebas unitarias y de widgets
flutter test
```

Si `flutter analyze` o `flutter test` arrojan algún error o advertencia, corrígelo de inmediato antes de notificar al usuario.
