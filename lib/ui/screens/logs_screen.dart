import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_log.dart';
import '../../providers/log_provider.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedLogIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final logProvider = context.watch<LogProvider>();
    final logs = logProvider.filteredLogs;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.logsTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.logsSubtitle,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Copy all button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.copyLogs),
                  onPressed: () {
                    final text = logProvider.exportFormattedText();
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.logsCopiedToast),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                // Clear button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceLight,
                    foregroundColor: AppTheme.accentRed,
                  ),
                  icon: const Icon(Icons.delete_sweep, size: 16),
                  label: Text(l10n.clearLogs),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: Text(l10n.clearLogsConfirmTitle),
                        content: Text(l10n.clearLogsConfirmMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
                            onPressed: () {
                              logProvider.clearLogs();
                              Navigator.of(ctx).pop();
                            },
                            child: Text(l10n.confirmClear, style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Stats Quick Filters Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                _buildStatPill(
                  label: l10n.all,
                  count: logProvider.totalCount,
                  color: Colors.white,
                  isSelected: logProvider.filterLevel == null,
                  onTap: () => logProvider.setFilterLevel(null),
                ),
                const SizedBox(width: 10),
                _buildStatPill(
                  label: l10n.errors,
                  count: logProvider.errorCount,
                  color: AppTheme.accentRed,
                  isSelected: logProvider.filterLevel == LogLevel.error,
                  onTap: () => logProvider.setFilterLevel(
                    logProvider.filterLevel == LogLevel.error ? null : LogLevel.error,
                  ),
                ),
                const SizedBox(width: 10),
                _buildStatPill(
                  label: l10n.warnings,
                  count: logProvider.warningCount,
                  color: AppTheme.accentYellow,
                  isSelected: logProvider.filterLevel == LogLevel.warning,
                  onTap: () => logProvider.setFilterLevel(
                    logProvider.filterLevel == LogLevel.warning ? null : LogLevel.warning,
                  ),
                ),
                const SizedBox(width: 10),
                _buildStatPill(
                  label: l10n.info,
                  count: logProvider.infoCount,
                  color: AppTheme.primary,
                  isSelected: logProvider.filterLevel == LogLevel.info,
                  onTap: () => logProvider.setFilterLevel(
                    logProvider.filterLevel == LogLevel.info ? null : LogLevel.info,
                  ),
                ),
                const SizedBox(width: 10),
                _buildStatPill(
                  label: l10n.successes,
                  count: logProvider.successCount,
                  color: AppTheme.accentGreen,
                  isSelected: logProvider.filterLevel == LogLevel.success,
                  onTap: () => logProvider.setFilterLevel(
                    logProvider.filterLevel == LogLevel.success ? null : LogLevel.success,
                  ),
                ),
              ],
            ),
          ),

          // Search and Category Chips
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => logProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: l10n.searchLogs,
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              logProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(
                        label: l10n.allCategories,
                        icon: Icons.apps,
                        isSelected: logProvider.filterCategory == null,
                        onTap: () => logProvider.setFilterCategory(null),
                      ),
                      ...LogCategory.values.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildCategoryChip(
                            label: l10n.logCategoryLabel(cat),
                            icon: cat.icon,
                            isSelected: logProvider.filterCategory == cat,
                            onTap: () => logProvider.setFilterCategory(
                              logProvider.filterCategory == cat ? null : cat,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 54, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noLogsFound,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.noLogsSubtitle,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final isExpanded = _expandedLogIds.contains(log.id);

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: log.level == LogLevel.error
                                ? AppTheme.accentRed.withValues(alpha: 0.4)
                                : AppTheme.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: log.details != null && log.details!.isNotEmpty
                                  ? () {
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedLogIds.remove(log.id);
                                        } else {
                                          _expandedLogIds.add(log.id);
                                        }
                                      });
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Level icon badge
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: log.level.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(log.level.icon, size: 16, color: log.level.color),
                                    ),
                                    const SizedBox(width: 12),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              // Level name
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: log.level.color.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  log.level.label,
                                                  style: TextStyle(
                                                    color: log.level.color,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Category
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.surfaceLight,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(log.category.icon, size: 11, color: AppTheme.textSecondary),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l10n.logCategoryLabel(log.category),
                                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              // Timestamp
                                              Text(
                                                log.formattedDateTime,
                                                style: const TextStyle(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // Message
                                          Text(
                                            log.message,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (log.details != null && log.details!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        size: 18,
                                        color: AppTheme.textMuted,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            // Expandable Details
                            if (isExpanded && log.details != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          l10n.technicalDetails,
                                          style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: log.details!));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(l10n.detailCopied),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            children: [
                                              const Icon(Icons.copy, size: 12, color: AppTheme.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                l10n.copy,
                                                style: const TextStyle(color: AppTheme.primary, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SelectableText(
                                      log.details!,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.6) : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
