import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Un widget enfocado para experiencia en TV y control remoto (D-Pad).
/// Proporciona realce visual (borde brillante, ligero escalado y brillo),
/// autodesplazamiento al enfocar y respuesta a los botones "OK/Select/Enter" del mando.
class TvFocusable extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext context, bool isFocused, bool isHovered)? builder;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool autofocus;
  final FocusNode? focusNode;
  final BorderRadius? borderRadius;
  final double scaleOnFocus;
  final Color? focusedBorderColor;
  final Color? focusedGlowColor;
  final Color? normalBorderColor;
  final Color? focusedBackgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool autoScroll;

  const TvFocusable({
    super.key,
    this.child,
    this.builder,
    this.onPressed,
    this.onLongPress,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius,
    this.scaleOnFocus = 1.03,
    this.focusedBorderColor,
    this.focusedGlowColor,
    this.normalBorderColor,
    this.focusedBackgroundColor,
    this.padding,
    this.margin,
    this.autoScroll = true,
  }) : assert(child != null || builder != null, 'Debes proporcionar child o builder');

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(TvFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused && widget.autoScroll) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleSelect() {
    if (widget.onPressed != null) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(10);
    final borderColor = _isFocused
        ? (widget.focusedBorderColor ?? AppTheme.primary)
        : (widget.normalBorderColor ?? Colors.transparent);
    final glowColor = widget.focusedGlowColor ?? AppTheme.primaryGlow;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            _handleSelect();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: _isFocused ? widget.scaleOnFocus : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutQuad,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutQuad,
              margin: widget.margin,
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: effectiveRadius,
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 2.0 : 1.0,
                ),
                color: _isFocused
                    ? (widget.focusedBackgroundColor ?? AppTheme.primary.withValues(alpha: 0.12))
                    : Colors.transparent,
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: glowColor,
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: widget.builder != null
                  ? widget.builder!(context, _isFocused, _isHovered)
                  : widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
