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
  bool _isCopied = false;

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
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final serverProvider = context.watch<StreamServerProvider>();
    final isRunning = serverProvider.isRunning;
    final streamUrl = serverProvider.streamUrl ?? 'http://127.0.0.1:8088/stream';
    final clients = serverProvider.clientCount;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status
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
            const SizedBox(height: 20),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 18),

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
                Text(
                  isRunning
                      ? 'Servidor activo en tu red local • $clients dispositivo(s) conectado(s)'
                      : 'Servidor detenido',
                  style: TextStyle(
                    color: isRunning ? AppTheme.accentGreen : AppTheme.accentRed,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // URL Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      streamUrl,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCopied ? AppTheme.accentGreen : AppTheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(_isCopied ? Icons.check : Icons.copy, size: 16),
                    label: Text(_isCopied ? '¡Copiado!' : 'Copiar URL', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: isRunning ? () => _copyToClipboard(streamUrl) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instructions Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo ver este vídeo en otro dispositivo?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Conecta tu Smart TV, iPhone, Android, Apple TV o PC a la misma red Wi-Fi que este Mac.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '2. En el otro dispositivo, abre VLC ("Abrir red"), Infuse, Kodi, navegador web o cualquier reproductor.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '3. Pega la URL copiada arriba y pulsa reproducir. El flujo se transmitirá en tiempo real.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isRunning)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      side: const BorderSide(color: AppTheme.accentRed),
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
