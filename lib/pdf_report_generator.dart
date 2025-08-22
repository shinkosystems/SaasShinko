import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:saas_gestao_financeira/models/transaction_model.dart';
import 'package:intl/intl.dart';

class PdfReportGenerator {
  static Future<Uint8List> generateTransactionReport(
    List<Transaction> transactions,
  ) async {
    final pdf = pw.Document();

    // Carrega a imagem da logo como bytes para funcionar em todas as plataformas
    final logoBytes = await rootBundle.load('assets/logocerta.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logo, height: 120),
              pw.SizedBox(width: 10),
              pw.Text(
                'Relatório de Transações',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Divider(height: 20),
          _buildSummary(transactions),
          pw.SizedBox(height: 20),
          _buildTransactionTable(transactions),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummary(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.value;
      } else {
        totalExpense += transaction.value;
      }
    }

    final balance = totalIncome - totalExpense;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        children: [
          _buildSummaryRow(
            'Total de Receitas:',
            totalIncome,
            PdfColors.green,
          ),
          _buildSummaryRow(
            'Total de Despesas:',
            totalExpense,
            PdfColors.red,
          ),
          _buildSummaryRow(
            'Saldo Final:',
            balance,
            (balance >= 0) ? PdfColors.blue : PdfColors.red,
            isBold: true,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String title,
    double value,
    PdfColor color, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(value)}',
            style: pw.TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionTable(List<Transaction> transactions) {
    final headers = ['Data', 'Descrição', 'Valor', 'Tipo'];
    final data = transactions.map((t) {
      return [
        DateFormat('dd/MM/yyyy').format(t.date),
        t.description,
        'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(t.value)}',
        t.type == TransactionType.income ? 'Receita' : 'Despesa',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.black),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }
}