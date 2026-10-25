import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/stream_server_provider.dart';
import '../theme/app_theme.dart';

class LanStreamDialog extends StatefulWidget {
  final String title;
  final String streamUrl;

  const LanStreamDialog({
    super.key,
    required this.title,
    required this.streamUrl,
  });

  @override
  State<LanStreamDialog> createState() => _LanStreamDialogState();
}

class _LanStreamDialogState extends State<LanStreamDialog> {
  bool _isCopiedWeb = false;
  bool _isCopiedStream = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StreamServerProvider>();
      if (!provider.isRunning) {
        provider.startSharing(
          targetStreamUrl: widget.streamUrl,
          title: widget.title,
        );
      }
    });
  }

  void _copyToClipboard(String url, bool isWeb) {
    Clipboard.setData(ClipboardData(text: url));
    setState(() {
      if (isWeb) {
        _isCopiedWeb = true;
      } else {
        _isCopiedStream = true;
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (isWeb) {
            _isCopiedWeb = false;
          } else {
            _isCopiedStream = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serverProvider = context.watch<StreamServerProvider>();
    final isRunning = serverProvider.isRunning;
    final webUrl = serverProvider.webPlayerUrl ?? 'http://127.0.0.1:8088/';
    final rawUrl = serverProvider.rawStreamUrl ?? 'http://127.0.0.1:8088/stream.ts';
    final clients = serverProvider.clientCount;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Close Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.cell_tower, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reenviar Vídeo por URL (Red Local)',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.title,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 16),

              // Server Status Badge
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isRunning ? AppTheme.accentGreen : AppTheme.accentRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isRunning ? AppTheme.accentGreen : AppTheme.accentRed).withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRunning
                          ? 'Servidor activo en tu red local • $clients dispositivo(s) conectado(s)'
                          : 'Servidor detenido',
                      style: TextStyle(
                        color: isRunning ? AppTheme.accentGreen : AppTheme.accentRed,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Card 1: Web Player (Browser)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.language, color: AppTheme.primary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '1. Navegador Web (Chrome, Safari, Móvil, PC)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              webUrl,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCopiedWeb ? AppTheme.accentGreen : AppTheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: Icon(_isCopiedWeb ? Icons.check : Icons.copy, size: 14),
                            label: Text(
                              _isCopiedWeb ? 'Copiado' : 'Copiar',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: isRunning ? () => _copyToClipboard(webUrl, true) : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✨ Abre esta URL en cualquier navegador para ver el reproductor web integrado sin descargar ningún archivo.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Card 2: External Player (VLC / Smart TV)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tv, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '2. Reproductores Externos (VLC, Smart TV, Kodi)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              rawUrl,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isCopiedStream ? AppTheme.accentGreen : Colors.white,
                              side: BorderSide(color: _isCopiedStream ? AppTheme.accentGreen : AppTheme.border),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: Icon(_isCopiedStream ? Icons.check : Icons.copy, size: 14),
                            label: Text(
                              _isCopiedStream ? 'Copiado' : 'Copiar',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: isRunning ? () => _copyToClipboard(rawUrl, false) : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '📺 Pega este enlace en "Abrir red" de VLC o en aplicaciones IPTV de Smart TV (TiviMate, SS IPTV, etc.).',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons (Detener / Iniciar / Cerrar)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isRunning)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentRed,
                        side: const BorderSide(color: AppTheme.accentRed),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('Detener Reenvío'),
                      onPressed: () {
                        serverProvider.stopSharing();
                      },
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Iniciar Reenvío'),
                      onPressed: () {
                        serverProvider.startSharing(
                          targetStreamUrl: widget.streamUrl,
                          title: widget.title,
                        );
                      },
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
