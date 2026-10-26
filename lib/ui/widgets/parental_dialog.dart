import 'package:flutter/material.dart';
import '../../services/parental_service.dart';
import '../theme/app_theme.dart';
import 'pin_code_dialog.dart';
import 'tv_focusable.dart';

/// Diálogo de configuración del Control Parental y Modo Infantil
class ParentalDialog extends StatefulWidget {
  const ParentalDialog({super.key});

  @override
  State<ParentalDialog> createState() => _ParentalDialogState();
}

class _ParentalDialogState extends State<ParentalDialog> {
  @override
  Widget build(BuildContext context) {
    final parental = ParentalService.instance;
    final isEnabled = parental.isEnabled;
    final isUnlocked = parental.isSessionUnlocked;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? (isUnlocked
                            ? AppTheme.accentGreen.withValues(alpha: 0.15)
                            : AppTheme.accentYellow.withValues(alpha: 0.15))
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEnabled
                          ? (isUnlocked ? AppTheme.accentGreen : AppTheme.accentYellow)
                          : AppTheme.border,
                    ),
                  ),
                  child: Icon(
                    isEnabled
                        ? (isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded)
                        : Icons.family_restroom_rounded,
                    color: isEnabled
                        ? (isUnlocked ? AppTheme.accentGreen : AppTheme.accentYellow)
                        : AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Control Parental & Modo Niños',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEnabled
                            ? (isUnlocked
                                ? 'Sesión desbloqueada temporalmente'
                                : 'Protección activa (PIN requerido)')
                            : 'Protege contenidos y bloquea canales para adultos',
                        style: TextStyle(
                          color: isEnabled
                              ? (isUnlocked ? AppTheme.accentGreen : AppTheme.accentYellow)
                              : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 16),

            if (!isEnabled) ...[
              // Estado: Desactivado
              const Text(
                'El control parental permite restringir el acceso a categorías para adultos (+18, XXX, Erótico) y proteger la gestión de listas mediante un PIN de 4 dígitos.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              TvFocusable(
                onPressed: () async {
                  final ok = await PinCodeDialog.show(
                    context,
                    mode: PinDialogMode.setup,
                    title: 'Activar Control Parental',
                  );
                  if (ok && mounted) {
                    setState(() {});
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, color: AppTheme.background, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Configurar PIN y Activar',
                        style: TextStyle(
                          color: AppTheme.background,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Estado: Activado
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTheme.primary,
                title: const Text(
                  'Bloquear categorías para adultos (+18 / XXX)',
                  style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                ),
                subtitle: const Text(
                  'Filtra automáticamente contenidos de adultos en TV, películas y series',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                value: parental.settings.lockAdultCategories,
                onChanged: (val) async {
                  await parental.updateOptions(lockAdult: val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTheme.primary,
                title: const Text(
                  'Bloquear ajustes y gestión de listas',
                  style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                ),
                subtitle: const Text(
                  'Exige el PIN para añadir, editar o eliminar perfiles y backups',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                value: parental.settings.lockSettings,
                onChanged: (val) async {
                  await parental.updateOptions(lockSettings: val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  if (isUnlocked)
                    Expanded(
                      child: TvFocusable(
                        onPressed: () {
                          parental.lockSession();
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentYellow),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_clock, color: AppTheme.accentYellow, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Bloquear Sesión',
                                style: TextStyle(
                                  color: AppTheme.accentYellow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: TvFocusable(
                        onPressed: () async {
                          final ok = await PinCodeDialog.show(
                            context,
                            mode: PinDialogMode.verify,
                          );
                          if (ok && mounted) {
                            setState(() {});
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_open_rounded, color: AppTheme.primary, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Desbloquear Sesión',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TvFocusable(
                      onPressed: () async {
                        final ok = await PinCodeDialog.show(
                          context,
                          mode: PinDialogMode.verify,
                          title: 'Verificar PIN Actual',
                        );
                        if (!context.mounted) return;
                        if (ok) {
                          await PinCodeDialog.show(
                            context,
                            mode: PinDialogMode.setup,
                            title: 'Nuevo Código PIN',
                          );
                          if (mounted) setState(() {});
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.password_rounded, color: AppTheme.textSecondary, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Cambiar PIN',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TvFocusable(
                onPressed: () async {
                  final ok = await PinCodeDialog.show(
                    context,
                    mode: PinDialogMode.verify,
                    title: 'Desactivar Control Parental',
                  );
                  if (ok && mounted) {
                    await parental.disable();
                    if (mounted) setState(() {});
                  }
                },
                borderRadius: BorderRadius.circular(8),
                focusedBorderColor: AppTheme.accentRed,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: const Text(
                    'Desactivar Control Parental',
                    style: TextStyle(
                      color: AppTheme.accentRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
