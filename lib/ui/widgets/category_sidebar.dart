import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../theme/app_theme.dart';
import 'tv_focusable.dart';

class CategoryCustomItem {
  final String id;
  final String name;
  final IconData icon;
  final int count;

  CategoryCustomItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.count,
  });
}

class CategorySidebar extends StatelessWidget {
  final List<ContentCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onSelectCategory;
  final int totalCount;
  final List<CategoryCustomItem> customTopItems;

  const CategorySidebar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
    required this.totalCount,
    this.customTopItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    final topCount = customTopItems.length + 1; // custom items + "Todos"

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'CATEGORÍAS',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: topCount + categories.length,
              itemBuilder: (context, index) {
                // Custom items first (Favoritos, Recientes)
                if (index < customTopItems.length) {
                  final custom = customTopItems[index];
                  final isSelected = selectedCategoryId == custom.id;
                  return _buildCategoryItem(
                    title: custom.name,
                    icon: custom.icon,
                    count: custom.count,
                    isSelected: isSelected,
                    onTap: () => onSelectCategory(custom.id),
                  );
                }

                // "Todos" item
                if (index == customTopItems.length) {
                  final isSelected = selectedCategoryId == 'all';
                  return Column(
                    children: [
                      _buildCategoryItem(
                        title: 'Todos',
                        icon: Icons.grid_view,
                        count: totalCount,
                        isSelected: isSelected,
                        onTap: () => onSelectCategory('all'),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Divider(color: AppTheme.border, height: 1),
                      ),
                    ],
                  );
                }

                // Normal categories
                final cat = categories[index - topCount];
                final isSelected = selectedCategoryId == cat.id;

                return _buildCategoryItem(
                  title: cat.name,
                  isSelected: isSelected,
                  onTap: () => onSelectCategory(cat.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String title,
    IconData? icon,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return TvFocusable(
      margin: const EdgeInsets.symmetric(vertical: 2),
      borderRadius: BorderRadius.circular(8),
      onPressed: onTap,
      builder: (context, isFocused, isHovered) {
        final activeColor = isFocused || isSelected ? AppTheme.primary : AppTheme.textPrimary;
        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.surfaceLight
                : (isFocused ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: isSelected && !isFocused
                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              leading: icon != null
                  ? Icon(
                      icon,
                      size: 18,
                      color: isFocused || isSelected ? AppTheme.primary : AppTheme.textMuted,
                    )
                  : null,
              title: Text(
                title,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: isFocused || isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: count != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          color: isFocused || isSelected ? AppTheme.primary : AppTheme.textMuted,
                          fontWeight: isFocused || isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    )
                  : null,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }
}
