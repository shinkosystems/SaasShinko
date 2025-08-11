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

    // 1. Calcular totais gerais para o resumo no início do relatório
    final double totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.value);
    final double totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.value);
    final double currentBalance = totalIncome - totalExpense;

    // Formatter para moeda
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // 2. Agrupar transações por mês e ano
    final Map<String, List<Transaction>> groupedByMonth = {};
    // ALTERAÇÃO AQUI: Ordenar as transações da mais recente para a mais antiga
    transactions.sort((a, b) => b.date.compareTo(a.date));
    for (var t in transactions) {
      final monthYear = DateFormat('MMMM yyyy', 'pt_BR').format(t.date);
      if (!groupedByMonth.containsKey(monthYear)) {
        groupedByMonth[monthYear] = [];
      }
      groupedByMonth[monthYear]!.add(t);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final List<pw.Widget> pageContent = [];

          // Adicionar o cabeçalho e o resumo geral (como já existiam)
          pageContent.add(
            pw.Center(
              child: pw.Text(
                'Relatório de Transações',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
          pageContent.add(pw.SizedBox(height: 20));
          pageContent.add(pw.Divider());
          pageContent.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Data do Relatório: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                ),
                pw.Text('Total de Transações: ${transactions.length}'),
              ],
            ),
          );
          pageContent.add(pw.SizedBox(height: 10));
          pageContent.add(pw.Divider());
          pageContent.add(pw.SizedBox(height: 20));
          pageContent.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumo Financeiro Geral:',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Saldo Atual:'),
                    pw.Text(
                      currencyFormatter.format(currentBalance),
                      style: pw.TextStyle(
                        color: currentBalance >= 0
                            ? PdfColors.blue
                            : PdfColors.red,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receitas Totais:'),
                    pw.Text(
                      currencyFormatter.format(totalIncome),
                      style: pw.TextStyle(color: PdfColors.green),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Despesas Totais:'),
                    pw.Text(
                      currencyFormatter.format(totalExpense),
                      style: pw.TextStyle(color: PdfColors.red),
                    ),
                  ],
                ),
                
              ],
            ),
          );
          pageContent.add(pw.SizedBox(height: 20));
          pageContent.add(pw.Divider());
          
          // 3. Iterar sobre os grupos de meses e gerar uma tabela para cada um
          groupedByMonth.forEach((monthYear, monthlyTransactions) {
            // Calcular resumo mensal
            final double monthlyIncome = monthlyTransactions
                .where((t) => t.type == TransactionType.income)
                .fold(0.0, (sum, item) => sum + item.value);
            final double monthlyExpense = monthlyTransactions
                .where((t) => t.type == TransactionType.expense)
                .fold(0.0, (sum, item) => sum + item.value);
            final double monthlyBalance = monthlyIncome - monthlyExpense;

            pageContent.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Transações de ${monthYear[0].toUpperCase()}${monthYear.substring(1)}:', // Capitaliza a primeira letra
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                   // Resumo mensal
                   pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Saldo do mês:'),
                        pw.Text(
                          currencyFormatter.format(monthlyBalance),
                          style: pw.TextStyle(
                            color: monthlyBalance >= 0
                                ? PdfColors.blue
                                : PdfColors.red,
                          ),
                        ),
                      ],
                   ),
                   pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Receitas do mês:'),
                        pw.Text(
                          currencyFormatter.format(monthlyIncome),
                          style: pw.TextStyle(color: PdfColors.green),
                        ),
                      ],
                   ),
                   pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Despesas do mês:'),
                        pw.Text(
                          currencyFormatter.format(monthlyExpense),
                          style: pw.TextStyle(color: PdfColors.red),
                        ),
                      ],
                   ),
                   pw.SizedBox(height: 10),
                   pw.Divider(),
                ],
              ),
            );

            // Adicionar a tabela para as transações deste mês
            pageContent.add(
              pw.Table.fromTextArray(
                headers: ['Data', 'Descrição', 'Tipo', 'Valor'],
                data: monthlyTransactions
                    .map(
                      (t) => [
                        DateFormat('dd/MM/yyyy').format(t.date),
                        t.description,
                        t.type == TransactionType.income ? 'Receita' : 'Despesa',
                        currencyFormatter.format(t.value),
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                border: pw.TableBorder.all(width: 1),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
            );
            pageContent.add(pw.SizedBox(height: 20)); // Espaço entre as tabelas
          });
          
          pageContent.add(pw.Center(child: pw.Text('*** Fim do Relatório ***')));
          
          return pageContent;
        },
      ),
    );

    return pdf.save();
  }
}