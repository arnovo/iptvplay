import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tv_focusable.dart';

/// Diálogo de búsqueda por voz optimizado para Smart TV y mandos a distancia
class VoiceSearchDialog extends StatefulWidget {
  final String currentQuery;
  final String title;

  const VoiceSearchDialog({
    super.key,
    this.currentQuery = '',
    this.title = 'Búsqueda por Voz en Smart TV',
  });

  static Future<String?> show(
    BuildContext context, {
    String currentQuery = '',
    String title = 'Búsqueda por Voz',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => VoiceSearchDialog(
        currentQuery: currentQuery,
        title: title,
      ),
    );
  }

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final List<String> _quickVoiceSuggestions = [
    'Fútbol',
    'Deportes',
    'Noticias',
    'Cine Acción',
    'Infantil',
    'Documentales',
    'HBO',
    '4K UHD',
    'Comedia',
    'Música',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentQuery);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de micrófono pulsante
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGlow,
                  border: Border.all(color: AppTheme.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: AppTheme.primary, size: 36),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Habla al micrófono de tu mando o escribe tu búsqueda',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Campo de texto de dictado
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ej. "Movistar Liga" o "Interestelar"...',
                prefixIcon: const Icon(Icons.record_voice_over, color: AppTheme.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                  onPressed: () => _controller.clear(),
                ),
              ),
              onSubmitted: (val) {
                Navigator.of(context).pop(val.trim());
              },
            ),
            const SizedBox(height: 18),

            // Sugerencias rápidas por voz
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sugerencias rápidas:',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickVoiceSuggestions.map((suggestion) {
                return TvFocusable(
                  onPressed: () {
                    Navigator.of(context).pop(suggestion);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: TvFocusable(
                    onPressed: () => Navigator.of(context).pop(null),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TvFocusable(
                    onPressed: () {
                      Navigator.of(context).pop(_controller.text.trim());
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Buscar',
                        style: TextStyle(
                          color: AppTheme.background,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
