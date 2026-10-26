import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/channel.dart';
import '../../models/epg_program.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/epg_provider.dart';
import '../../services/parental_service.dart';
import '../theme/app_theme.dart';
import '../widgets/epg_program_modal.dart';
import '../widgets/tv_focusable.dart';

/// Pantalla de Guía de TV (EPG) en formato de cuadrícula tradicional (tipo decodificador)
class EpgGridScreen extends StatefulWidget {
  const EpgGridScreen({super.key});

  @override
  State<EpgGridScreen> createState() => _EpgGridScreenState();
}

class _EpgGridScreenState extends State<EpgGridScreen> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalChannelController = ScrollController();
  final ScrollController _verticalGridController = ScrollController();

  static const double _pixelsPerMinute = 3.5;
  static const double _rowHeight = 64.0;
  static const double _channelColWidth = 180.0;
  static const double _timeHeaderHeight = 44.0;

  late DateTime _gridStartTime;
  late DateTime _gridEndTime;
  late int _totalMinutes;

  @override
  void initState() {
    super.initState();
    // Ventana de 24 horas: desde 4 horas antes de ahora hasta 20 horas después
    final now = DateTime.now();
    _gridStartTime = DateTime(now.year, now.month, now.day, now.hour).subtract(const Duration(hours: 4));
    _gridEndTime = _gridStartTime.add(const Duration(hours: 24));
    _totalMinutes = _gridEndTime.difference(_gridStartTime).inMinutes;

    // Sincronizar scroll vertical entre columna de canales y cuadrícula
    _verticalGridController.addListener(() {
      if (_verticalChannelController.hasClients &&
          _verticalChannelController.offset != _verticalGridController.offset) {
        _verticalChannelController.jumpTo(_verticalGridController.offset);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNow(animate: false);
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalChannelController.dispose();
    _verticalGridController.dispose();
    super.dispose();
  }

  void _scrollToNow({bool animate = true}) {
    if (!_horizontalController.hasClients) return;
    final now = DateTime.now();
    final elapsedMinutes = now.difference(_gridStartTime).inMinutes;
    final targetOffset = (elapsedMinutes * _pixelsPerMinute) - 150.0;
    final clamped = targetOffset.clamp(0.0, _horizontalController.position.maxScrollExtent);

    if (animate) {
      _horizontalController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _horizontalController.jumpTo(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final epg = context.watch<EpgProvider>();
    final parental = context.watch<ParentalService>();

    // Canales filtrados respetando control parental
    final channels = catalog.content.channels.where((c) {
      return !parental.isCategoryRestricted(categoryId: c.categoryId, categoryName: '');
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.grid_on_rounded, color: AppTheme.primary, size: 22),
            SizedBox(width: 10),
            Text(
              'Guía de Programación (EPG)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Botón ir a "AHORA"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TvFocusable(
              onPressed: () => _scrollToNow(animate: true),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGlow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location, color: AppTheme.primary, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Ir al Momento Actual',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
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
      body: channels.isEmpty
          ? const Center(
              child: Text(
                'No hay canales disponibles en esta lista',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : Column(
              children: [
                // Cabecera superior con las horas sincronizadas
                SizedBox(
                  height: _timeHeaderHeight,
                  child: Row(
                    children: [
                      // Esquina fija para el encabezado de "CANAL"
                      Container(
                        width: _channelColWidth,
                        height: _timeHeaderHeight,
                        color: AppTheme.surface,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text(
                          'CANALES',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: AppTheme.border),
                      // Línea de tiempo horizontal desplazable
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: _buildTimelineHeader(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),

                // Cuerpo de canales y eventos
                Expanded(
                  child: Row(
                    children: [
                      // Columna izquierda fija de canales
                      SizedBox(
                        width: _channelColWidth,
                        child: ListView.builder(
                          controller: _verticalChannelController,
                          physics: const ClampingScrollPhysics(),
                          itemCount: channels.length,
                          itemBuilder: (context, index) {
                            final channel = channels[index];
                            return _buildChannelHeader(channel, index + 1);
                          },
                        ),
                      ),
                      const VerticalDivider(width: 1, color: AppTheme.border),

                      // Cuadrícula central de eventos desplazable en ambas dimensiones
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: SizedBox(
                            width: _totalMinutes * _pixelsPerMinute,
                            child: Stack(
                              children: [
                                // Lista vertical de filas de eventos
                                ListView.builder(
                                  controller: _verticalGridController,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: channels.length,
                                  itemBuilder: (context, index) {
                                    final channel = channels[index];
                                    final schedule = epg.getChannelSchedule(
                                      channel.id,
                                      channelTvgId: channel.epgChannelId,
                                      channelName: channel.name,
                                    );
                                    return _buildChannelProgramsRow(channel, schedule);
                                  },
                                ),

                                // Línea vertical roja indicadora de "AHORA"
                                _buildNowIndicatorLine(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Construye la cabecera horizontal de horas (marcas cada 30 minutos)
  Widget _buildTimelineHeader() {
    final intervalCount = (_totalMinutes / 30).ceil();
    final timeFormat = DateFormat('HH:mm');

    return Row(
      children: List.generate(intervalCount, (index) {
        final time = _gridStartTime.add(Duration(minutes: index * 30));
        return Container(
          width: 30 * _pixelsPerMinute,
          height: _timeHeaderHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(right: BorderSide(color: AppTheme.border, width: 0.8)),
          ),
          child: Text(
            timeFormat.format(time),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }),
    );
  }

  /// Construye la tarjeta fija de un canal en la columna izquierda
  Widget _buildChannelHeader(Channel channel, int number) {
    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Text(
            '$number',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          if (channel.logoUrl != null && channel.logoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                channel.logoUrl!,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.tv, size: 22, color: AppTheme.textMuted),
              ),
            )
          else
            const Icon(Icons.tv, size: 22, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              channel.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la fila de programas para un canal específico
  Widget _buildChannelProgramsRow(Channel channel, List<EpgProgram> schedule) {
    final relevant = schedule.where((p) {
      return p.end.isAfter(_gridStartTime) && p.start.isBefore(_gridEndTime);
    }).toList();

    return Container(
      height: _rowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.8)),
      ),
      child: Stack(
        children: [
          if (relevant.isEmpty)
            // Bloque sin EPG
            Positioned(
              left: 0,
              right: 0,
              top: 4,
              bottom: 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sin información de programación para ${channel.name}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ...relevant.map((program) {
              final visibleStart = program.start.isBefore(_gridStartTime) ? _gridStartTime : program.start;
              final visibleEnd = program.end.isAfter(_gridEndTime) ? _gridEndTime : program.end;

              final startOffsetMinutes = visibleStart.difference(_gridStartTime).inMinutes;
              final durationMinutes = visibleEnd.difference(visibleStart).inMinutes;

              final left = startOffsetMinutes * _pixelsPerMinute;
              final width = (durationMinutes * _pixelsPerMinute) - 4.0;

              return Positioned(
                left: left,
                width: width < 40 ? 40 : width,
                top: 4,
                bottom: 4,
                child: _buildProgramCard(channel, program),
              );
            }),
        ],
      ),
    );
  }

  /// Tarjeta de programa enfocable con TvFocusable
  Widget _buildProgramCard(Channel channel, EpgProgram program) {
    final isLive = program.isCurrent;

    return TvFocusable(
      onPressed: () => _showProgramDetailsModal(channel, program),
      borderRadius: BorderRadius.circular(8),
      scaleOnFocus: 1.02,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isLive ? AppTheme.primaryGlow : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLive ? AppTheme.primary : AppTheme.border,
            width: isLive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (isLive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
                Text(
                  program.formattedTimeRange,
                  style: TextStyle(
                    color: isLive ? AppTheme.primary : AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              program.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLive ? AppTheme.primary : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: isLive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Línea vertical indicadora del momento actual "AHORA"
  Widget _buildNowIndicatorLine() {
    final now = DateTime.now();
    if (now.isBefore(_gridStartTime) || now.isAfter(_gridEndTime)) {
      return const SizedBox.shrink();
    }

    final minutes = now.difference(_gridStartTime).inMinutes;
    final left = minutes * _pixelsPerMinute;

    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          width: 2,
          color: AppTheme.accentRed,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AHORA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra el modal con opciones del programa (reproducir, programar recordatorio, catchup)
  void _showProgramDetailsModal(Channel channel, EpgProgram program) {
    EpgProgramDetailsModal.show(
      context,
      channel: channel,
      program: program,
      onReminderChanged: () {
        if (mounted) setState(() {});
      },
    );
  }
}

