import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/order_entity.dart';

/// Genera documentos PDF para tickets de cocina y de cliente.
///
/// Soporta formato 80mm (impresora térmica estándar) con disposición
/// optimizada para lectura rápida.
class TicketGenerator {
  TicketGenerator._();

  /// Ancho estándar de ticket térmico (80mm ≈ 226pt).
  static const _ticketWidth = 226.0;

  // ---------------------------------------------------------------------------
  // Ticket de cocina
  // ---------------------------------------------------------------------------

  /// Genera un ticket de cocina con los platos del pedido y notas especiales.
  static pw.Document kitchenTicket({
    required OrderEntity order,
    String? tableName,
  }) {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_ticketWidth, double.infinity),
        margin: const pw.EdgeInsets.all(8),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Text(
                '--- COCINA ---',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1),

            // Info pedido
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Pedido #${order.orderNumber}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (tableName != null)
                  pw.Text(
                    tableName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              _formatDateTime(order.createdAt),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            if (order.waiterName != null)
              pw.Text(
                'Camarero: ${order.waiterName}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 4),

            // Items
            ...order.items.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          '${item.quantity}x',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(
                          child: pw.Text(
                            item.name,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 20, top: 2),
                        child: pw.Text(
                          '>> ${item.notes}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            pw.Divider(thickness: 1),
            pw.Center(
              child: pw.Text(
                'Total items: ${order.itemCount}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  // ---------------------------------------------------------------------------
  // Ticket de cliente
  // ---------------------------------------------------------------------------

  /// Genera un ticket de cliente con desglose de precios.
  static pw.Document clientTicket({
    required OrderEntity order,
    String? tableName,
    String? restaurantName,
  }) {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_ticketWidth, double.infinity),
        margin: const pw.EdgeInsets.all(8),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Restaurant name
            if (restaurantName != null)
              pw.Center(
                child: pw.Text(
                  restaurantName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 0.5),

            // Info pedido
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Pedido #${order.orderNumber}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (tableName != null)
                  pw.Text(tableName, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Text(
              _formatDateTime(order.createdAt),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            if (order.waiterName != null)
              pw.Text(
                'Atendido por: ${order.waiterName}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            pw.Divider(thickness: 0.5),

            // Items con precios
            ...order.items.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  children: [
                    pw.Text(
                      '${item.quantity}x',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Text(
                        item.name,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      '${item.totalPrice.toStringAsFixed(2)} €',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),

            // Totales
            _pdfTotalRow('Subtotal', order.subtotal),
            if (order.taxAmount > 0) _pdfTotalRow('Impuestos', order.taxAmount),
            if (order.discountAmount > 0)
              _pdfTotalRow('Descuento', -order.discountAmount),
            pw.SizedBox(height: 2),
            pw.Divider(thickness: 1),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${order.total.toStringAsFixed(2)} €',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 1),

            // Método de pago
            if (order.paymentMethod != null)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    'Pagado con: ${_paymentLabel(order.paymentMethod!)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ),

            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                '¡Gracias por su visita!',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static pw.Widget _pdfTotalRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            '${amount.toStringAsFixed(2)} €',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _paymentLabel(String method) {
    return switch (method) {
      'cash' => 'Efectivo',
      'card' => 'Tarjeta',
      _ => method,
    };
  }
}
