import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/profile_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/user_activity_provider.dart';
import 'providers/epg_provider.dart';
import 'providers/download_provider.dart';
import 'providers/stream_server_provider.dart';
import 'providers/log_provider.dart';
import 'providers/playback_provider.dart';
import 'providers/multiview_provider.dart';
import 'services/parental_service.dart';
import 'services/reminder_service.dart';
import 'providers/language_provider.dart';
import 'l10n/app_localizations.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => UserActivityProvider()),
        ChangeNotifierProvider(create: (_) => EpgProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => StreamServerProvider()),
        ChangeNotifierProvider(create: (_) => LogProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackProvider()),
        ChangeNotifierProvider(create: (_) => MultiviewProvider()),
        ChangeNotifierProvider.value(value: ParentalService.instance..init()),
        ChangeNotifierProvider.value(value: ReminderService.instance..init()),
      ],
      child: const IptvApp(),
    ),
  );
}

class IptvApp extends StatelessWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'IPTV Play',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: languageProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShellScreen(),
    );
  }
}
