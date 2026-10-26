import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/multiview_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tv_focusable.dart';

class MultiviewScreen extends StatefulWidget {
  final Channel? initialChannel;

  const MultiviewScreen({super.key, this.initialChannel});

  @override
  State<MultiviewScreen> createState() => _MultiviewScreenState();
}

class _MultiviewScreenState extends State<MultiviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialChannel != null) {
        context.read<MultiviewProvider>().playInSlot(0, widget.initialChannel!);
      }
    });
  }

  void _showChannelPickerForSlot(int slotIndex) {
    final catalog = context.read<CatalogProvider>();
    final channels = catalog.content.channels;
    final multiview = context.read<MultiviewProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = channels.where((c) {
              return searchQuery.isEmpty ||
                  c.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.grid_view, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Asignar Canal al Recuadro ${slotIndex + 1}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textMuted),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (val) => setModalState(() => searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Buscar canal para Multiview...',
                        prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron canales',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final channel = filtered[i];
                                return TvFocusable(
                                  borderRadius: BorderRadius.circular(8),
                                  onPressed: () {
                                    multiview.playInSlot(slotIndex, channel);
                                    Navigator.of(ctx).pop();
                                  },
                                  builder: (context, isFocused, isHovered) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: isFocused
                                            ? AppTheme.primary.withValues(alpha: 0.15)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        leading: channel.logoUrl != null &&
                                                channel.logoUrl!.isNotEmpty
                                            ? Image.network(
                                                channel.logoUrl!,
                                                width: 32,
                                                height: 32,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(Icons.tv, color: AppTheme.textMuted),
                                              )
                                            : const Icon(Icons.tv, color: AppTheme.textMuted),
                                        title: Text(
                                          channel.name,
                                          style: TextStyle(
                                            color: isFocused
                                                ? AppTheme.primary
                                                : AppTheme.textPrimary,
                                            fontWeight: isFocused
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: const Icon(Icons.add_circle_outline,
                                            size: 18, color: AppTheme.primary),
                                        onTap: () {
                                          multiview.playInSlot(slotIndex, channel);
                                          Navigator.of(ctx).pop();
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final multiview = context.watch<MultiviewProvider>();
    final slots = multiview.slots;
    final gridCount = multiview.activeGridCount;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.goBack) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.surface.withValues(alpha: 0.85),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.dashboard_customize,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MULTIVIEW DEPORTES Y DIRECTOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'El canal resaltado tiene el audio activo • Pulsa OK para cambiar sonido',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Grid mode selector
                    Row(
                      children: [
                        _buildGridModeButton(
                          title: '2 Canales',
                          count: 2,
                          isSelected: gridCount == 2,
                          onPressed: () => multiview.setGridCount(2),
                        ),
                        const SizedBox(width: 6),
                        _buildGridModeButton(
                          title: '4 Canales',
                          count: 4,
                          isSelected: gridCount == 4,
                          onPressed: () => multiview.setGridCount(4),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      tooltip: 'Salir de Multiview',
                      onPressed: () {
                        multiview.stopAll();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              // Grid Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: gridCount == 2
                      ? Row(
                          children: [
                            Expanded(child: _buildSlotCell(slots[0], 0, multiview)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildSlotCell(slots[1], 1, multiview)),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildSlotCell(slots[0], 0, multiview)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildSlotCell(slots[1], 1, multiview)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildSlotCell(slots[2], 2, multiview)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildSlotCell(slots[3], 3, multiview)),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridModeButton({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return TvFocusable(
      borderRadius: BorderRadius.circular(6),
      onPressed: onPressed,
      builder: (context, isFocused, isHovered) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary
                : (isFocused ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected || isFocused ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotCell(MultiviewSlot slot, int slotIndex, MultiviewProvider multiview) {
    final isFocusedSlot = multiview.focusedSlotIndex == slotIndex;
    final hasChannel = slot.channel != null;

    return TvFocusable(
      borderRadius: BorderRadius.circular(12),
      onPressed: () {
        if (hasChannel) {
          multiview.setFocusedSlot(slotIndex);
        } else {
          _showChannelPickerForSlot(slotIndex);
        }
      },
      builder: (context, isTvFocused, isHovered) {
        final highlight = isFocusedSlot || isTvFocused;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? AppTheme.primary : AppTheme.border,
              width: highlight ? 2.5 : 1,
            ),
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGlow.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasChannel)
                Video(
                  controller: slot.controller,
                  fit: BoxFit.contain,
                  controls: NoVideoControls,
                )
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.add, color: AppTheme.primary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Añadir canal a recuadro ${slotIndex + 1}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Overlay Information for active channel
              if (hasChannel)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isFocusedSlot ? AppTheme.primary : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              slot.isMuted ? Icons.volume_off : Icons.volume_up,
                              color: slot.isMuted ? AppTheme.textMuted : AppTheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                slot.channel!.name,
                                style: TextStyle(
                                  color: isFocusedSlot ? AppTheme.primary : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Quick action to swap or close channel
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                        ),
                        onPressed: () => multiview.closeSlot(slotIndex),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
