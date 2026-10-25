import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../services/backup_service.dart';
import '../theme/app_theme.dart';

class BackupDialog extends StatefulWidget {
  const BackupDialog({super.key});

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  final BackupService _backupService = BackupService();
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = true;

  Future<void> _exportBackup() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    final savedPath = await _backupService.exportBackupToFile();

    if (mounted) {
      setState(() {
        _isProcessing = false;
        if (savedPath != null) {
          _isSuccess = true;
          _statusMessage = 'Copia exportada exitosamente en:\n$savedPath';
        } else {
          _isSuccess = false;
          _statusMessage = 'Exportación cancelada';
        }
      });
    }
  }

  Future<void> _importBackup() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    final success = await _backupService.importBackupFromFile();

    if (!mounted) return;

    if (success) {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.loadProfiles();
      if (!mounted) return;
      await context.read<UserActivityProvider>().loadActivity();

      if (!mounted) return;
      if (profileProvider.activeProfile != null) {
        context.read<CatalogProvider>().loadCatalog(profileProvider.activeProfile!);
      }

      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _statusMessage = '¡Copia de seguridad restaurada correctamente!\nListas, favoritos y progresos recuperados.';
      });
    } else {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'No se pudo restaurar el archivo o la selección fue cancelada.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cloud_sync, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Copia de Seguridad y Nube',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Exporta o importa tus listas, favoritos y progreso',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
            const SizedBox(height: 20),

            // Export Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.file_upload_outlined, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exportar Copia (.json)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Guarda todas tus listas y configuraciones en un archivo local', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isProcessing ? null : _exportBackup,
                    child: const Text('Exportar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Import Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.file_download_outlined, color: AppTheme.secondary, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Restaurar Copia (.json)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Recupera listas y favoritos desde un archivo previo', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    onPressed: _isProcessing ? null : _importBackup,
                    child: const Text('Importar'),
                  ),
                ],
              ),
            ),

            if (_isProcessing) ...[
              const SizedBox(height: 20),
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                ),
              ),
            ],

            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? AppTheme.accentGreen.withValues(alpha: 0.15) : AppTheme.accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isSuccess ? AppTheme.accentGreen.withValues(alpha: 0.4) : AppTheme.accentRed.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isSuccess ? AppTheme.accentGreen : AppTheme.accentRed,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
