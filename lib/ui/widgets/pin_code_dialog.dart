import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/parental_service.dart';
import '../theme/app_theme.dart';
import 'tv_focusable.dart';

enum PinDialogMode {
  verify,
  setup,
}

/// Diálogo de teclado numérico virtual optimizado para mandos de TV (D-Pad) y teclado.
class PinCodeDialog extends StatefulWidget {
  final PinDialogMode mode;
  final String title;
  final String subtitle;

  const PinCodeDialog({
    super.key,
    this.mode = PinDialogMode.verify,
    this.title = 'Control Parental',
    this.subtitle = 'Introduce el código PIN de 4 dígitos',
  });

  /// Muestra el diálogo y devuelve true si se validó o configuró correctamente
  static Future<bool> show(
    BuildContext context, {
    PinDialogMode mode = PinDialogMode.verify,
    String? title,
    String? subtitle,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PinCodeDialog(
        mode: mode,
        title: title ?? (mode == PinDialogMode.setup ? 'Crear PIN de Seguridad' : 'Control Parental'),
        subtitle: subtitle ??
            (mode == PinDialogMode.setup
                ? 'Introduce un PIN de 4 dígitos para proteger contenidos'
                : 'Introduce el código PIN de 4 dígitos'),
      ),
    );
    return result ?? false;
  }

  @override
  State<PinCodeDialog> createState() => _PinCodeDialogState();
}

class _PinCodeDialogState extends State<PinCodeDialog> {
  final FocusNode _keyboardFocusNode = FocusNode();
  String _enteredPin = '';
  String _firstEnteredPin = ''; // Para modo setup (confirmación)
  bool _isConfirming = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage = null;
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _handleCompletePin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _handleCompletePin() async {
    if (widget.mode == PinDialogMode.verify) {
      final success = ParentalService.instance.unlockWithPin(_enteredPin);
      if (success) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'PIN incorrecto. Inténtalo de nuevo.';
          _enteredPin = '';
        });
      }
    } else {
      // Modo setup
      if (!_isConfirming) {
        setState(() {
          _firstEnteredPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _firstEnteredPin) {
          final success = await ParentalService.instance.setPinAndEnable(newPin: _enteredPin);
          if (mounted) Navigator.of(context).pop(success);
        } else {
          setState(() {
            _errorMessage = 'Los PINs no coinciden. Empieza de nuevo.';
            _enteredPin = '';
            _firstEnteredPin = '';
            _isConfirming = false;
          });
        }
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
        _onDigitPressed('0');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
        _onDigitPressed('1');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
        _onDigitPressed('2');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
        _onDigitPressed('3');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
        _onDigitPressed('4');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
        _onDigitPressed('5');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
        _onDigitPressed('6');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
        _onDigitPressed('7');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
        _onDigitPressed('8');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
        _onDigitPressed('9');
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
        _onBackspace();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop(false);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _isConfirming ? 'Confirma tu PIN' : widget.title;
    final subtitleText = _isConfirming ? 'Vuelve a introducir los 4 dígitos' : widget.subtitle;

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border, width: 1.5),
        ),
        child: Container(
          width: 380,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera con Icono
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGlow,
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                titleText,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitleText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Indicadores de los 4 dígitos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  final isError = _errorMessage != null;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isError
                          ? AppTheme.accentRed
                          : isFilled
                              ? AppTheme.primary
                              : Colors.transparent,
                      border: Border.all(
                        color: isError
                            ? AppTheme.accentRed
                            : isFilled
                                ? AppTheme.primary
                                : AppTheme.border,
                        width: 2,
                      ),
                      boxShadow: isFilled && !isError
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Mensaje de Error si aplica
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.accentRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 14),

              // Teclado numérico virtual navegable por D-Pad
              _buildNumpad(),

              const SizedBox(height: 16),

              // Botón Cancelar
              TvFocusable(
                onPressed: () => Navigator.of(context).pop(false),
                borderRadius: BorderRadius.circular(10),
                focusedBorderColor: AppTheme.accentRed,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        _buildNumpadRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _buildNumpadRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _buildNumpadRow(['7', '8', '9']),
        const SizedBox(height: 10),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildNumButton(
            text: d,
            onPressed: () => _onDigitPressed(d),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Backspace
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildActionButton(
            icon: Icons.backspace_outlined,
            onPressed: _onBackspace,
          ),
        ),
        // 0
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildNumButton(
            text: '0',
            onPressed: () => _onDigitPressed('0'),
          ),
        ),
        // Clear all / Reset
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildActionButton(
            icon: Icons.clear_all_rounded,
            onPressed: () {
              setState(() {
                _enteredPin = '';
                _errorMessage = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNumButton({required String text, required VoidCallback onPressed}) {
    return TvFocusable(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 66,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onPressed}) {
    return TvFocusable(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 66,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: AppTheme.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
