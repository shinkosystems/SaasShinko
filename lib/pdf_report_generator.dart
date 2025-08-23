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

    // Agrupa as transações por mês e ano
    final groupedTransactions = <String, List<Transaction>>{};
    // Garante que a lista de transações esteja ordenada por data
    transactions.sort((a, b) => a.date.compareTo(b.date));

    for (var transaction in transactions) {
      final key = DateFormat('MMMM yyyy', 'pt_BR').format(transaction.date);
      if (!groupedTransactions.containsKey(key)) {
        groupedTransactions[key] = [];
      }
      groupedTransactions[key]!.add(transaction);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final List<pw.Widget> content = [];

          // 1. Adiciona o cabeçalho com a logo e o título, cada um em sua própria linha e centralizados
          content.add(
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Image(logo, height: 130),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Relatório de Transações',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );

          content.add(pw.Divider(height: 20));

          // 2. Adiciona o resumo GERAL de todas as transações
          content.add(
            pw.Text(
              'Resumo Geral',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
          content.add(pw.SizedBox(height: 10));
          content.add(_buildSummary(transactions));

          content.add(pw.SizedBox(height: 20));
          content.add(pw.Divider());

          // 3. Itera sobre os meses e adiciona o resumo e a tabela para cada um
          groupedTransactions.forEach((month, monthlyTransactions) {
            content.add(pw.SizedBox(height: 20));
            content.add(
              pw.Text(
                'Mês: $month',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 10));

            // Adiciona o resumo do mês específico
            content.add(_buildSummary(monthlyTransactions));
            
            content.add(pw.SizedBox(height: 10));
            content.add(_buildTransactionTable(monthlyTransactions));
            content.add(pw.SizedBox(height: 20));
          });

          return content;
        },
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