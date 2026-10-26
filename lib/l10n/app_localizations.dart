import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/sort_option.dart';
import '../models/app_log.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('es'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
  ];

  bool get isEnglish => locale.languageCode == 'en';

  // Navigation & Shell
  String get appTitle => 'IPTV Play';
  String get smartPlayer => 'Smart Player';
  String get liveTv => isEnglish ? 'Live TV' : 'TV en Vivo';
  String get moviesVod => isEnglish ? 'Movies (VOD)' : 'Películas (VOD)';
  String get series => isEnglish ? 'Series' : 'Series';
  String get downloadsPvr => isEnglish ? 'Downloads & PVR' : 'Descargas & PVR';
  String get logs => isEnglish ? 'Logs' : 'Registros';
  String get backup => isEnglish ? 'Backup & Restore' : 'Copia de seguridad';
  String get reloadList => isEnglish ? 'Reload Playlist' : 'Recargar lista';
  String get addList => isEnglish ? 'Add Playlist' : 'Añadir lista';
  String get fullscreen => isEnglish ? 'Fullscreen' : 'Pantalla completa';
  String get exitFullscreen =>
      isEnglish ? 'Exit Fullscreen' : 'Salir de pantalla completa';
  String get language => isEnglish ? 'Language' : 'Idioma';
  String get activeLanguageName => isEnglish ? 'English' : 'Español';
  String get switchLanguage =>
      isEnglish ? 'Cambiar a Español' : 'Switch to English';
  String get settings => isEnglish ? 'Settings' : 'Configuración';
  String get settingsSubtitle => isEnglish
      ? 'Playlists, parental control, logs and system preferences'
      : 'Listas, control parental, logs y preferencias del sistema';

  // Profiles & Onboarding
  String get noActiveProfile =>
      isEnglish ? 'No active playlist' : 'Sin lista activa';
  String get switchProfile => isEnglish ? 'Switch playlist' : 'Cambiar lista';
  String get tapToAdd => isEnglish ? 'Tap to add' : 'Toca para añadir';
  String get welcomeTitle =>
      isEnglish ? 'Welcome to IPTV Play!' : '¡Bienvenido a IPTV Play!';
  String get welcomeSubtitle => isEnglish
      ? 'To start watching live TV, movies and series, add your first playlist.'
      : 'Para empezar a ver TV en vivo, películas y series, añade tu primera lista.';
  String get addPlaylistButton => isEnglish
      ? 'Add Playlist or Xtream Account'
      : 'Añadir Lista o Cuenta Xtream';
  String get loadingCatalogTitle => isEnglish
      ? 'Loading channels and catalog...'
      : 'Cargando canales y catálogo...';
  String get loadingCatalogSubtitle => isEnglish
      ? 'Processing M3U playlist / Xtream server...'
      : 'Procesando lista M3U / Servidor Xtream...';
  String get catalogErrorTitle =>
      isEnglish ? 'Error loading playlist' : 'Error al cargar la lista';
  String get retry => isEnglish ? 'Retry' : 'Reintentar';
  String get manageProfiles =>
      isEnglish ? 'My Playlists' : 'Mis Listas de Canales';
  String get activeBadge => isEnglish ? 'ACTIVE' : 'ACTIVO';
  String get delete => isEnglish ? 'Delete' : 'Eliminar';
  String get edit => isEnglish ? 'Edit' : 'Editar';
  String get activate => isEnglish ? 'Activate' : 'Activar';
  String get playlistName =>
      isEnglish ? 'Playlist Name' : 'Nombre de la lista';
  String get playlistType =>
      isEnglish ? 'Playlist Type' : 'Tipo de lista';
  String get m3uUrl => isEnglish ? 'M3U / M3U8 URL' : 'URL M3U / M3U8';
  String get xtreamServer =>
      isEnglish ? 'Server URL (e.g. http://server.com:80)' : 'URL Servidor (ej. http://servidor.com:80)';
  String get username => isEnglish ? 'Username' : 'Usuario';
  String get password => isEnglish ? 'Password' : 'Contraseña';
  String get saveAndLoad =>
      isEnglish ? 'Save and Load' : 'Guardar y Cargar';
  String get cancel => isEnglish ? 'Cancel' : 'Cancelar';
  String get confirmDeleteTitle =>
      isEnglish ? 'Delete Playlist' : 'Eliminar lista';
  String confirmDeleteMessage(String name) => isEnglish
      ? 'Are you sure you want to delete "$name"?'
      : '¿Estás seguro de que deseas eliminar "$name"?';

  // Live TV
  String get searchChannels =>
      isEnglish ? 'Search channels...' : 'Buscar canal...';
  String get allChannels =>
      isEnglish ? 'All Channels' : 'Todos los canales';
  String get favorites => isEnglish ? 'Favorites' : 'Favoritos';
  String get recents => isEnglish ? 'Recent Channels' : 'Canales Recientes';
  String get clearRecents =>
      isEnglish ? 'Clear recents' : 'Limpiar recientes';
  String get noChannelsFound =>
      isEnglish ? 'No channels found' : 'No se encontraron canales';
  String get nowAiring => isEnglish ? 'Now:' : 'Ahora:';
  String get nextAiring => isEnglish ? 'Next:' : 'A continuación:';
  String get replayTv => isEnglish ? 'Replay TV' : 'Replay TV';
  String get recordChannel =>
      isEnglish ? 'Record Channel' : 'Grabar canal';
  String get stopRecording =>
      isEnglish ? 'Stop Recording' : 'Detener grabación';
  String get lanStreamRelay =>
      isEnglish ? 'LAN Stream Server' : 'Reenviar en red local';

  // VOD & Series
  String get searchMovies =>
      isEnglish ? 'Search movies...' : 'Buscar películas...';
  String get searchSeries =>
      isEnglish ? 'Search series...' : 'Buscar series...';
  String get continueWatching =>
      isEnglish ? 'Continue Watching' : 'Continuar viendo';
  String get allCategories =>
      isEnglish ? 'All Categories' : 'Todas las categorías';
  String get noMoviesFound =>
      isEnglish ? 'No movies found' : 'No se encontraron películas';
  String get noSeriesFound =>
      isEnglish ? 'No series found' : 'No se encontraron series';
  String get seasons => isEnglish ? 'Seasons' : 'Temporadas';
  String get episodes => isEnglish ? 'Episodes' : 'Episodios';
  String get season => isEnglish ? 'Season' : 'Temporada';
  String get episode => isEnglish ? 'Episode' : 'Episodio';
  String get play => isEnglish ? 'Play' : 'Reproducir';
  String get resumePlayback =>
      isEnglish ? 'Resume Playback' : 'Reanudar';
  String get download => isEnglish ? 'Download' : 'Descargar';
  String get downloading =>
      isEnglish ? 'Downloading...' : 'Descargando...';
  String get downloaded => isEnglish ? 'Downloaded' : 'Descargado';
  String get close => isEnglish ? 'Close' : 'Cerrar';
  String get synopsis => isEnglish ? 'Synopsis' : 'Sinopsis';
  String get noSynopsis => isEnglish
      ? 'No synopsis available.'
      : 'Sinopsis no disponible.';
  String get year => isEnglish ? 'Year' : 'Año';
  String get duration => isEnglish ? 'Duration' : 'Duración';
  String get rating => isEnglish ? 'Rating' : 'Valoración';
  String get minutes => isEnglish ? 'min' : 'min';

  // Sort & Filters
  String get sort => isEnglish ? 'Sort' : 'Ordenar';
  String get sortDefault => isEnglish ? 'Default' : 'Por defecto';
  String get sortNameAsc => isEnglish ? 'Name (A - Z)' : 'Nombre (A - Z)';
  String get sortNameDesc => isEnglish ? 'Name (Z - A)' : 'Nombre (Z - A)';
  String get sortDateDesc =>
      isEnglish ? 'Newest First' : 'Más recientes primero';
  String get sortDateAsc =>
      isEnglish ? 'Oldest First' : 'Más antiguos primero';
  String get sortRatingDesc =>
      isEnglish ? 'Highest Rated' : 'Mejor valorados';

  String sortLabel(SortOption opt) {
    switch (opt) {
      case SortOption.defaultOrder:
        return sortDefault;
      case SortOption.nameAsc:
        return sortNameAsc;
      case SortOption.nameDesc:
        return sortNameDesc;
      case SortOption.dateDesc:
        return sortDateDesc;
      case SortOption.dateAsc:
        return sortDateAsc;
      case SortOption.ratingDesc:
        return sortRatingDesc;
    }
  }

  // Downloads & PVR
  String get tabActive => isEnglish ? 'In Progress' : 'En curso';
  String get tabCompleted => isEnglish ? 'Completed' : 'Completadas';
  String get tabRecordings =>
      isEnglish ? 'PVR Recordings' : 'Grabaciones PVR';
  String get noActiveDownloads =>
      isEnglish ? 'No active downloads' : 'Sin descargas activas';
  String get noCompletedDownloads =>
      isEnglish ? 'No downloaded content yet' : 'No hay contenidos descargados aún';
  String get noRecordings =>
      isEnglish ? 'No recorded broadcasts yet' : 'No hay emisiones grabadas aún';
  String get pause => isEnglish ? 'Pause' : 'Pausar';
  String get resume => isEnglish ? 'Resume' : 'Reanudar';
  String get speed => isEnglish ? 'Speed' : 'Velocidad';
  String get timeRemaining =>
      isEnglish ? 'Time remaining' : 'Tiempo restante';
  String get totalSpaceUsed =>
      isEnglish ? 'Total storage used' : 'Espacio total ocupado';
  String get openFolder => isEnglish ? 'Open folder' : 'Abrir carpeta';
  String get resumePausedDownloadTitle =>
      isEnglish ? 'Resume paused download' : 'Reanudar descarga pausada';
  String get resumePausedDownloadsTitle =>
      isEnglish ? 'Resume paused downloads' : 'Reanudar descargas pausadas';
  String resumeSinglePausedMessage(String title) => isEnglish
      ? 'An incomplete download was detected:\n"$title"\n\nWould you like to resume it now?'
      : 'Se ha detectado una descarga incompleta:\n"$title"\n\n¿Deseas reanudarla ahora desde donde se quedó?';
  String resumeMultiplePausedMessage(int count) => isEnglish
      ? '$count incomplete downloads detected.\n\nWould you like to resume them now?'
      : 'Se han detectado $count descargas incompletas.\n\n¿Deseas reanudarlas ahora?';
  String get later => isEnglish ? 'Later' : 'Más tarde';
  String get resumeAll =>
      isEnglish ? 'Resume all' : 'Reanudar todas';

  // Player
  String get audioTracks =>
      isEnglish ? 'Audio Tracks' : 'Pistas de Audio';
  String get subtitles => isEnglish ? 'Subtitles' : 'Subtítulos';
  String get disabled => isEnglish ? 'Disabled' : 'Desactivado';
  String get aspectRatio =>
      isEnglish ? 'Aspect Ratio' : 'Relación de Aspecto';
  String get fit => isEnglish ? 'Fit' : 'Ajustar';
  String get fill => isEnglish ? 'Fill' : 'Rellenar';
  String get stretch => isEnglish ? 'Stretch' : 'Estirar';
  String get playbackSpeed =>
      isEnglish ? 'Playback Speed' : 'Velocidad';
  String get channelList =>
      isEnglish ? 'Channel List' : 'Lista de Canales';
  String get recordingLiveBadge =>
      isEnglish ? 'RECORDING LIVE' : 'GRABANDO DIRECTO';
  String get liveBadge => isEnglish ? 'LIVE' : 'EN VIVO';
  String get seekForward10s =>
      isEnglish ? '+10s' : '+10s';
  String get seekBackward10s =>
      isEnglish ? '-10s' : '-10s';

  // EPG & Catch-up
  String get channelSchedule =>
      isEnglish ? 'Channel Schedule' : 'Guía de Programación';
  String get noEpgAvailable =>
      isEnglish ? 'No program guide available for this channel.' : 'Sin información de programación disponible.';
  String get catchupTitle =>
      isEnglish ? 'Replay Guide (Last 7 Days)' : 'Guía de Replay (Últimos 7 días)';
  String get selectDay => isEnglish ? 'Select Day' : 'Seleccionar día';
  String get watchReplay => isEnglish ? 'Watch Replay' : 'Ver emisión';

  // Logs
  String get logsTitle =>
      isEnglish ? 'Activity Log & Events' : 'Registro de Actividad y Logs';
  String get logsSubtitle => isEnglish
      ? 'Network, player, downloads, and system event history'
      : 'Historial de eventos de red, reproductor, descargas y estado del sistema';
  String get searchLogs =>
      isEnglish ? 'Filter by message, URL or details...' : 'Filtrar por mensaje, URL o detalle...';
  String get filterLevel => isEnglish ? 'Level' : 'Nivel';
  String get filterCategory =>
      isEnglish ? 'Category' : 'Categoría';
  String get all => isEnglish ? 'All' : 'Todos';
  String get errors => isEnglish ? 'Errors' : 'Errores';
  String get warnings => isEnglish ? 'Warnings' : 'Advertencias';
  String get info => isEnglish ? 'Info' : 'Información';
  String get successes => isEnglish ? 'Success' : 'Éxitos';
  String get clearLogs => isEnglish ? 'Clear' : 'Limpiar';
  String get clearLogsConfirmTitle =>
      isEnglish ? 'Clear logs?' : '¿Vaciar registros?';
  String get clearLogsConfirmMessage => isEnglish
      ? 'All saved system logs will be permanently deleted.'
      : 'Se eliminarán todos los registros guardados del sistema.';
  String get confirmClear => isEnglish ? 'Clear' : 'Vaciar';
  String get copyLogs => isEnglish ? 'Copy logs' : 'Copiar registros';
  String get logsCopiedToast => isEnglish
      ? 'Logs copied to clipboard'
      : 'Registros copiados al portapapeles';
  String get noLogsFound => isEnglish
      ? 'No logs match the selected filters'
      : 'No hay registros con los filtros seleccionados';
  String get noLogsSubtitle => isEnglish
      ? 'Player, network, and download events will automatically appear here'
      : 'Los eventos del reproductor, red y descargas aparecerán aquí automáticamente';
  String get technicalDetails =>
      isEnglish ? 'TECHNICAL DETAILS' : 'DETALLES TÉCNICOS';
  String get copy => isEnglish ? 'Copy' : 'Copiar';
  String get detailCopied =>
      isEnglish ? 'Details copied' : 'Detalle copiado';

  String logCategoryLabel(LogCategory cat) {
    if (!isEnglish) return cat.label;
    switch (cat) {
      case LogCategory.network:
        return 'Network / IPTV';
      case LogCategory.player:
        return 'Player';
      case LogCategory.epg:
        return 'EPG Guide';
      case LogCategory.downloads:
        return 'Downloads / PVR';
      case LogCategory.server:
        return 'LAN Server';
      case LogCategory.system:
        return 'System';
    }
  }

  // LAN Stream Relay
  String get lanServerTitle =>
      isEnglish ? 'LAN Stream Relay Server' : 'Servidor de Streaming en Red Local';
  String get lanServerSubtitle => isEnglish
      ? 'Re-stream current playback across other devices on your local network without extra IPTV connections.'
      : 'Reenvía la emisión actual a otros dispositivos de tu red local sin gastar conexiones de tu proveedor.';
  String get lanStreamUrl =>
      isEnglish ? 'Local Stream URL' : 'Enlace de transmisión local';
  String get copyUrl => isEnglish ? 'Copy link' : 'Copiar enlace';
  String get lanServerActive =>
      isEnglish ? 'Server is active on port 8088' : 'Servidor activo en el puerto 8088';
  String get lanServerInactive =>
      isEnglish ? 'Server is currently stopped' : 'Servidor actualmente detenido';

  // Backup & Restore
  String get backupTitle =>
      isEnglish ? 'Backup & Sincronización' : 'Copia de seguridad y sincronización';
  String get exportBackup =>
      isEnglish ? 'Export Backup (.json)' : 'Exportar copia (.json)';
  String get importBackup =>
      isEnglish ? 'Import Backup (.json)' : 'Importar copia (.json)';
  String get backupExportSuccess => isEnglish
      ? 'Backup successfully exported!'
      : '¡Copia de seguridad exportada con éxito!';
  String get backupImportSuccess => isEnglish
      ? 'Backup imported successfully! Profiles and settings restored.'
      : '¡Copia importada con éxito! Perfiles y ajustes restaurados.';

  // Backup Dialog details
  String get backupDialogTitle =>
      isEnglish ? 'Backup & Cloud' : 'Copia de Seguridad y Nube';
  String get backupDialogSubtitle => isEnglish
      ? 'Export or import your playlists, favorites, and watch progress'
      : 'Exporta o importa tus listas, favoritos y progreso';
  String get exportBackupTitle =>
      isEnglish ? 'Export Backup (.json)' : 'Exportar Copia (.json)';
  String get exportBackupDesc => isEnglish
      ? 'Save all your playlists and settings to a local file'
      : 'Guarda todas tus listas y configuraciones en un archivo local';
  String get exportAction => isEnglish ? 'Export' : 'Exportar';
  String get restoreBackupTitle =>
      isEnglish ? 'Restore Backup (.json)' : 'Restaurar Copia (.json)';
  String get restoreBackupDesc => isEnglish
      ? 'Recover playlists and favorites from a previous backup file'
      : 'Recupera listas y favoritos desde un archivo previo';
  String get restoreAction => isEnglish ? 'Import' : 'Importar';
  String get backupExportCancelled =>
      isEnglish ? 'Export cancelled' : 'Exportación cancelada';
  String get backupImportFailed => isEnglish
      ? 'Could not restore file or selection was cancelled.'
      : 'No se pudo restaurar el archivo o la selección fue cancelada.';
  String get backupImportSuccessDesc => isEnglish
      ? 'Backup restored successfully!\nPlaylists, favorites, and progress recovered.'
      : '¡Copia de seguridad restaurada correctamente!\nListas, favoritos y progresos recuperados.';
  String backupExportSuccessPath(String path) => isEnglish
      ? 'Backup exported successfully to:\n$path'
      : 'Copia exportada exitosamente en:\n$path';

  // LAN Stream Relay Dialog
  String get lanRelayTitle => isEnglish
      ? 'Relay Video via URL (Local Network)'
      : 'Reenviar Vídeo por URL (Red Local)';
  String lanServerActiveStatus(int clients) => isEnglish
      ? 'Server active on local network • $clients connected device(s)'
      : 'Servidor activo en tu red local • $clients dispositivo(s) conectado(s)';
  String get lanServerStoppedStatus =>
      isEnglish ? 'Server stopped' : 'Servidor detenido';
  String get lanContinuousStreamCardTitle => isEnglish
      ? 'Continuous Stream URL (stream.ts)'
      : 'Enlace de Flujo Continuo (stream.ts)';
  String get copied => isEnglish ? 'Copied!' : '¡Copiado!';
  String get copyUrlAction => isEnglish ? 'Copy URL' : 'Copiar URL';
  String get lanServerInfoNote => isEnglish
      ? '📺 Native playback in VLC ("Open Network"), Smart TV (TiviMate, SS IPTV), Kodi, Infuse or any player on your local network with full video and audio.'
      : '📺 Reproducción nativa en VLC ("Abrir red"), Smart TV (TiviMate, SS IPTV), Kodi, Infuse o cualquier reproductor en tu red local con audio y vídeo completos.';
  String get stopRelay =>
      isEnglish ? 'Stop Relay' : 'Detener Reenvío';
  String get startRelay =>
      isEnglish ? 'Start Relay' : 'Iniciar Reenvío';

  // Catchup Dialog
  String get catchup7DaysTitle => isEnglish
      ? 'Replay TV (Last 7 Days)'
      : 'Replay TV (Últimos 7 días)';
  String get noRecordedBroadcasts => isEnglish
      ? 'No recorded broadcasts available'
      : 'No hay emisiones grabadas disponibles';
  String get noCatchupProviderSupport => isEnglish
      ? 'This channel or provider does not support Catch-up / Replay TV'
      : 'Este canal o proveedor no soporta Catch-up / Replay TV';
  String get watch => isEnglish ? 'Watch' : 'Ver';

  // Channel EPG Dialog
  String get channelEpgTitle => isEnglish
      ? 'Program Guide (EPG)'
      : 'Guía de Programación (EPG)';
  String get noEpgDataChannel => isEnglish
      ? 'No EPG data available for this channel'
      : 'No hay datos de EPG para este canal';
  String get noEpgCheckTvgId => isEnglish
      ? 'Make sure the playlist contains a valid tvg-id or XMLTV guide'
      : 'Asegúrate de que la lista contenga un tvg-id o archivo XMLTV válido';
  String get nowBadge => isEnglish ? 'NOW' : 'AHORA';

  // Miniplayer
  String get nowPlaying =>
      isEnglish ? 'Now Playing' : 'Reproduciendo';
  String get liveOnAir =>
      isEnglish ? 'LIVE' : 'EN DIRECTO';
  String get seekRewind10sTooltip =>
      isEnglish ? 'Rewind 10 seconds' : 'Retroceder 10 segundos';
  String get seekForward10sTooltip =>
      isEnglish ? 'Forward 10 seconds' : 'Avanzar 10 segundos';
  String get openPlayerTooltip => isEnglish
      ? 'Maximize (Open player)'
      : 'Hacerlo más grande (Abrir reproductor)';
  String get stopAndCloseTooltip =>
      isEnglish ? 'Stop and close' : 'Detener y cerrar';

  // Screen Format & Aspect Ratio
  String get screenFormatTitle => isEnglish
      ? 'Screen Format & Aspect Ratio'
      : 'Formato y Modo de Pantalla';
  String get aspectCoverTitle => isEnglish
      ? 'Full Screen (Cover / Zoom)'
      : 'Pantalla completa (Llenar / Zoom)';
  String get aspectCoverSubtitle => isEnglish
      ? 'Fills entire screen without black borders'
      : 'Llena toda la pantalla sin bordes negros';
  String get aspectContainTitle => isEnglish
      ? 'Fit to Screen (Original)'
      : 'Ajustar a pantalla (Original)';
  String get aspectContainSubtitle => isEnglish
      ? 'Preserves native video aspect ratio'
      : 'Mantiene la proporción nativa del vídeo';
  String get aspectFillTitle => isEnglish
      ? 'Stretch (16:9)'
      : 'Estirar (16:9)';
  String get aspectFillSubtitle => isEnglish
      ? 'Scales image to widescreen 16:9'
      : 'Escala la imagen a formato panorámico';
  String get windowFullscreenExit => isEnglish
      ? 'Exit Fullscreen (Window)'
      : 'Salir de pantalla completa (Ventana)';
  String get windowFullscreenEnter => isEnglish
      ? 'Enter Fullscreen (Window)'
      : 'Activar pantalla completa (Ventana)';
  String get windowFullscreenSubtitle => isEnglish
      ? 'Maximizes window across your monitor (or press F key)'
      : 'Maximiza la ventana ocupando todo tu monitor (o pulsa tecla F)';
  String get aspectNameCover => isEnglish ? 'Cover' : 'Completa';
  String get aspectNameContain => isEnglish ? 'Fit' : 'Ajustar';
  String get aspectNameFill => isEnglish ? 'Stretch' : 'Estirar';
  String screenRatioLabel(String name) => isEnglish
      ? 'Screen: $name'
      : 'Pantalla: $name';
  String tracksAvailableCount(int count) => isEnglish
      ? '$count available'
      : '$count disponible(s)';
  String get noAudioTracksAvailable => isEnglish
      ? 'No additional audio tracks available'
      : 'No hay pistas adicionales disponibles';
  String languagesAvailableCount(int count) => isEnglish
      ? '$count language(s)'
      : '$count idioma(s)';
  String get noSubtitlesAvailable => isEnglish
      ? 'No subtitles available'
      : 'No hay subtítulos disponibles';
  String get subtitlesDisabled =>
      isEnglish ? 'Disabled' : 'Desactivados';
  String get playbackError =>
      isEnglish ? 'Playback error' : 'Error de reproducción';
  String get audioTracksTooltip =>
      isEnglish ? 'Audio tracks' : 'Pistas de audio';
  String get subtitlesTooltip =>
      isEnglish ? 'Subtitles' : 'Subtítulos';
  String get removeFavoriteTooltip =>
      isEnglish ? 'Remove from favorites' : 'Quitar de favoritos';
  String get addFavoriteTooltip =>
      isEnglish ? 'Add to favorites' : 'Añadir a favoritos';
  String get stopPvrTooltip =>
      isEnglish ? 'Stop PVR recording' : 'Detener grabación PVR';
  String get recordPvrTooltip =>
      isEnglish ? 'Record broadcast' : 'Grabar transmisión';
  String recordingStoppedToast(String title) => isEnglish
      ? 'Recording of "$title" stopped and saved in Downloads'
      : 'Grabación de "$title" detenida y guardada en Descargas';
  String recordingStartedToast(String title) => isEnglish
      ? 'Recording "$title" in the background...'
      : 'Grabando "$title" en segundo plano...';
  String get downloadedOpenFolderTooltip => isEnglish
      ? 'Downloaded (click to open folder)'
      : 'Descargado (clic para abrir carpeta)';
  String get downloadOfflineTooltip => isEnglish
      ? 'Download for offline viewing'
      : 'Descargar para ver sin conexión';
  String get downloadStartedToast => isEnglish
      ? 'Download started in background'
      : 'Descarga iniciada en segundo plano';
  String get lanShareTooltip => isEnglish
      ? 'Relay stream to local network (VLC / Smart TV)'
      : 'Reenviar emisión a red local (VLC / Smart TV)';
  String get exitFullscreenTooltip => isEnglish
      ? 'Exit fullscreen'
      : 'Salir de pantalla completa';
  String get enterFullscreenTooltip => isEnglish
      ? 'Fullscreen'
      : 'Pantalla completa';
  String get stopAndClosePlayerTooltip => isEnglish
      ? 'Stop and close player'
      : 'Detener y cerrar reproductor';
  String get lanSharingActiveTooltip => isEnglish
      ? 'Streaming on local network (Active)'
      : 'Transmitiendo en red local (Activo)';
  String get lanSharingInactiveTooltip => isEnglish
      ? 'Relay video via URL (Local Network)'
      : 'Reenviar vídeo por URL (Red Local)';
  String get minimizeTooltip => isEnglish
      ? 'Minimize to bottom bar'
      : 'Minimizar a la barra inferior';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
