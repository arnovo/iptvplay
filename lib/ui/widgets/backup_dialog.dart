import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_activity_provider.dart';
import '../../services/backup_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class BackupDialog extends StatefulWidget {
  const BackupDialog({super.key});

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  final BackupService _backupService = BackupService();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    final pwd = _passwordController.text.trim();
    final savedPath = await _backupService.exportBackupToFile(
      password: pwd.isEmpty ? null : pwd,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        if (savedPath != null) {
          _isSuccess = true;
          _statusMessage = context.l10n.backupExportSuccessPath(savedPath);
        } else {
          _isSuccess = false;
          _statusMessage = context.l10n.backupExportCancelled;
        }
      });
    }
  }

  Future<void> _importBackup() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    final pwd = _passwordController.text.trim();
    final success = await _backupService.importBackupFromFile(
      password: pwd.isEmpty ? null : pwd,
    );

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
        _statusMessage = context.l10n.backupImportSuccessDesc;
      });
    } else {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = context.l10n.backupImportFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.backupDialogTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.backupDialogSubtitle,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
            const SizedBox(height: 16),

            // Contraseña de Cifrado AES-256 (Opcional)
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                labelText: 'Contraseña de cifrado AES-256 (Opcional)',
                hintText: 'Dejar en blanco para copia sin cifrar',
                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.exportBackupTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(l10n.exportBackupDesc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isProcessing ? null : _exportBackup,
                    child: Text(l10n.exportAction, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.restoreBackupTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(l10n.restoreBackupDesc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    onPressed: _isProcessing ? null : _importBackup,
                    child: Text(l10n.restoreAction),
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
