import 'package:flutter/material.dart';
import '../../../models/series_item.dart';
import '../../theme/app_theme.dart';
import '../tv_focusable.dart';

/// Fila horizontal de series destacadas
class HubSeriesRow extends StatelessWidget {
  final List<SeriesItem> seriesList;
  final VoidCallback onNavigateToSeries;

  const HubSeriesRow({
    super.key,
    required this.seriesList,
    required this.onNavigateToSeries,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seriesList.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final s = seriesList[index];
          return TvFocusable(
            onPressed: onNavigateToSeries,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Container(
                        color: AppTheme.surfaceLight,
                        child: s.posterUrl != null
                            ? Image.network(
                                s.posterUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.tv, color: AppTheme.textMuted),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.tv, color: AppTheme.textMuted),
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
