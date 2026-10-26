import 'package:dio/dio.dart';
import '../models/app_log.dart';
import 'log_service.dart';

/// Centralized security service for URL sanitization and SSRF / loopback protection.
class UrlSanitizerService {
  /// Local stream relay default port used for LAN sharing
  static const int localRelayPort = 8088;

  /// Validates that a URL is strictly formatted and uses only http:// or https://.
  static bool isValidWebUrl(String? urlString) {
    if (urlString == null || urlString.trim().isEmpty) return false;
    final trimmed = urlString.trim();

    try {
      final uri = Uri.parse(trimmed);
      if (!uri.hasScheme || !uri.hasAuthority) return false;
      final scheme = uri.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        LogService.instance.warning(
          LogCategory.network,
          'URL rechazada: esquema no seguro ($scheme)',
          details: 'URL: $urlString',
        );
        return false;
      }
      return uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Sanitizes and validates a URL string. Throws [FormatException] if invalid.
  static String sanitizeUrl(String urlString) {
    if (!isValidWebUrl(urlString)) {
      throw FormatException('URL no válida o esquema inseguro (solo http/https): $urlString');
    }
    return urlString.trim();
  }

  /// Checks whether a URI targets loopback, link-local, or cloud metadata IP addresses.
  static bool isLoopbackOrBlocked(Uri uri, {bool allowInternalRelay = true}) {
    final host = uri.host.trim().toLowerCase();

    // Exception for the internal LAN relay server if explicitly permitted
    if (allowInternalRelay && uri.port == localRelayPort) {
      if (host == '127.0.0.1' || host == 'localhost' || host == '::1') {
        return false;
      }
    }

    if (host == 'localhost' || host == '0.0.0.0' || host == '::1' || host == '0:0:0:0:0:0:0:1') {
      return true;
    }

    // Platform-agnostic IPv4 loopback, link-local and cloud metadata check
    final ipv4Parts = host.split('.');
    if (ipv4Parts.length == 4) {
      final numbers = ipv4Parts.map(int.tryParse).toList();
      if (numbers.every((n) => n != null && n >= 0 && n <= 255)) {
        final b0 = numbers[0]!;
        final b1 = numbers[1]!;
        // 127.0.0.0/8 loopback range
        if (b0 == 127) return true;
        // 0.0.0.0
        if (b0 == 0) return true;
        // 169.254.0.0/16 link-local and cloud metadata (169.254.169.254)
        if (b0 == 169 && b1 == 254) return true;
      }
    }

    return false;
  }

  /// Creates a Dio interceptor to block SSRF attempts and loopback calls.
  static Interceptor createSsrfInterceptor({bool allowInternalRelay = true}) {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final uri = options.uri;
        final scheme = uri.scheme.toLowerCase();

        if (scheme != 'http' && scheme != 'https') {
          final err = 'Petición bloqueada: esquema no permitido ($scheme). Solo se permite http/https.';
          LogService.instance.error(
            LogCategory.network,
            'Bloqueo de seguridad (Esquema no permitido)',
            details: 'URI: $uri',
          );
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: err,
              message: err,
            ),
          );
        }

        if (isLoopbackOrBlocked(uri, allowInternalRelay: allowInternalRelay)) {
          final err = 'Petición bloqueada por Anti-SSRF: destino loopback o local no autorizado ($uri)';
          LogService.instance.error(
            LogCategory.network,
            'Bloqueo Anti-SSRF hacia host local',
            details: 'Host: ${uri.host} • Puerto: ${uri.port}',
          );
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: err,
              message: err,
            ),
          );
        }

        return handler.next(options);
      },
    );
  }
}
