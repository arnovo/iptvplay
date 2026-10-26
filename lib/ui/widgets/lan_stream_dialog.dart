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

  void _copyToClipboard(String url) {
    Clipboard.setData(ClipboardData(text: url));
    setState(() {
      _isCopiedStream = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopiedStream = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serverProvider = context.watch<StreamServerProvider>();
    final isRunning = serverProvider.isRunning;
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

              // Stream URL Card (stream.ts)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tv, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Enlace de Flujo Continuo (stream.ts)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
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
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCopiedStream ? AppTheme.accentGreen : AppTheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: Icon(_isCopiedStream ? Icons.check : Icons.copy, size: 15),
                            label: Text(
                              _isCopiedStream ? '¡Copiado!' : 'Copiar URL',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: isRunning ? () => _copyToClipboard(rawUrl) : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '📺 Reproducción nativa en VLC ("Abrir red"), Smart TV (TiviMate, SS IPTV), Kodi, Infuse o cualquier reproductor en tu red local con audio y vídeo completos.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
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
