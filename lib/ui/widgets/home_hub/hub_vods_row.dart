import 'package:flutter/material.dart';
import '../../../models/vod_item.dart';
import '../../theme/app_theme.dart';
import '../media_detail_sheet.dart';
import '../tv_focusable.dart';

/// Fila horizontal de películas VOD destacadas
class HubVodsRow extends StatelessWidget {
  final List<VodItem> vods;

  const HubVodsRow({
    super.key,
    required this.vods,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final vod = vods[index];
          return TvFocusable(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => MediaDetailSheet(vod: vod),
              );
            },
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
                        child: vod.posterUrl != null
                            ? Image.network(
                                vod.posterUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.movie, color: AppTheme.textMuted),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.movie, color: AppTheme.textMuted),
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      vod.name,
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
