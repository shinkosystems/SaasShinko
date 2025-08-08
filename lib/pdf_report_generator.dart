import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:saas_gestao_financeira_backup/models/transaction_model.dart';

// Classe que gera o PDF
class PdfReportGenerator {
  static Future<Uint8List> generateTransactionReport(
    List<Transaction> transactions,
  ) async {
    final pdf = pw.Document();

    final double totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.value);
    final double totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.value);
    final double currentBalance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text(
                'Relatório de Transações - Shinko',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Data do Relatório: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                ),
                pw.Text('Total de Transações: ${transactions.length}'),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumo Financeiro:',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receitas Totais:'),
                    pw.Text(
                      'R\$ ${totalIncome.toStringAsFixed(2)}',
                      style: pw.TextStyle(color: PdfColors.green),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Despesas Totais:'),
                    pw.Text(
                      'R\$ ${totalExpense.toStringAsFixed(2)}',
                      style: pw.TextStyle(color: PdfColors.red),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Saldo Atual:'),
                    pw.Text(
                      'R\$ ${currentBalance.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: currentBalance >= 0
                            ? PdfColors.blue
                            : PdfColors.red,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
            ),
            pw.Text(
              'Detalhes das Transações:',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Data', 'Descrição', 'Tipo', 'Valor'],
              data: transactions
                  .map(
                    (t) => [
                      DateFormat('dd/MM/yyyy').format(t.date),
                      t.description,
                      t.type == TransactionType.income ? 'Receita' : 'Despesa',
                      'R\$ ${t.value.toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              border: pw.TableBorder.all(width: 1),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(5),
            ),
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('*** Fim do Relatório ***')),
          ];
        },
      ),
    );
    return pdf.save();
  }
}
