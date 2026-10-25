import 'package:flutter/material.dart';
import '../../models/sort_option.dart';
import '../theme/app_theme.dart';

class SortFilterButton extends StatelessWidget {
  final SortOption currentOption;
  final List<SortOption> availableOptions;
  final ValueChanged<SortOption> onSelected;

  const SortFilterButton({
    super.key,
    required this.currentOption,
    required this.availableOptions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      tooltip: 'Ordenar contenido',
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      initialValue: currentOption,
      onSelected: onSelected,
      itemBuilder: (context) {
        return availableOptions.map((opt) {
          final isSelected = opt == currentOption;
          return PopupMenuItem<SortOption>(
            value: opt,
            child: Row(
              children: [
                Icon(
                  opt.icon,
                  size: 18,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check,
                    size: 16,
                    color: AppTheme.primary,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: currentOption != SortOption.defaultOrder
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: currentOption != SortOption.defaultOrder
                ? AppTheme.primary.withValues(alpha: 0.5)
                : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentOption.icon,
              size: 16,
              color: currentOption != SortOption.defaultOrder
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              currentOption == SortOption.defaultOrder
                  ? 'Ordenar'
                  : currentOption.label,
              style: TextStyle(
                color: currentOption != SortOption.defaultOrder
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: currentOption != SortOption.defaultOrder
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: currentOption != SortOption.defaultOrder
                  ? AppTheme.primary
                  : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
