import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:printing/printing.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../data/services/ticket_generator.dart';
import '../../domain/entities/order_entity.dart';

/// Página de previsualización e impresión de tickets.
///
/// Muestra dos tabs: ticket de cocina y ticket de cliente.
/// Usa el paquete `printing` para vista previa y envío a impresora.
class TicketPreviewPage extends ConsumerStatefulWidget {
  final OrderEntity order;
  final String? tableName;
  final String? restaurantName;

  const TicketPreviewPage({
    super.key,
    required this.order,
    this.tableName,
    this.restaurantName,
  });

  @override
  ConsumerState<TicketPreviewPage> createState() => _TicketPreviewPageState();
}

class _TicketPreviewPageState extends ConsumerState<TicketPreviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.ticketPreviewTitle(
          widget.order.orderNumber.toString(),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              icon: Icon(
                PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
              ),
              text: context.l10n.ticketPreviewKitchenTab,
            ),
            Tab(
              icon: Icon(
                PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
              ),
              text: context.l10n.ticketPreviewClientTab,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _TicketTab(
            label: context.l10n.ticketPreviewKitchenTab,
            buildPdf: () async => Uint8List.fromList(
              await TicketGenerator.kitchenTicket(
                order: widget.order,
                tableName: widget.tableName,
              ).save(),
            ),
          ),
          _TicketTab(
            label: context.l10n.ticketPreviewClientTab,
            buildPdf: () async => Uint8List.fromList(
              await TicketGenerator.clientTicket(
                order: widget.order,
                tableName: widget.tableName,
                restaurantName: widget.restaurantName,
              ).save(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab individual con vista previa PDF y botón de imprimir.
class _TicketTab extends StatelessWidget {
  final String label;
  final Future<Uint8List> Function() buildPdf;

  const _TicketTab({required this.label, required this.buildPdf});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PdfPreview(
            build: (_) => buildPdf(),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: 'ticket_${label.toLowerCase()}.pdf',
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            MediaQuery.of(context).padding.bottom + AppTheme.spacingMd,
          ),
          child: TactileWrapper(
            onTap: () async {
              final bytes = await buildPdf();
              await Printing.directPrintPdf(
                printer:
                    await Printing.pickPrinter(context: context) ??
                    const Printer(url: ''),
                onLayout: (_) => bytes,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.printer(PhosphorIconsStyle.fill),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.ticketPreviewPrintButton(label),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
