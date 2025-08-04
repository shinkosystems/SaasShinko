import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:saas_gestao_financeira/add_income_screen.dart';
import 'package:saas_gestao_financeira/add_expense_screen.dart';
import 'package:saas_gestao_financeira/transaction_model.dart';
import 'package:saas_gestao_financeira/transaction_detail_screen.dart';
import 'package:saas_gestao_financeira/pages/user_page.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:saas_gestao_financeira/pdf_report_generator.dart';
import 'package:saas_gestao_financeira/services/auth_service.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _areNumbersVisible = true;

  final SupabaseClient supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAssetExistence();
    _fetchTransactions();
  }

  // MÉTODO DE DEPURACAO PARA O ASSET DA LOGO
  Future<void> _checkAssetExistence() async {
    try {
      await DefaultAssetBundle.of(context)
          .load('assets/logocerta.png'); // <--- Use o nome exato aqui!
      print(
          '>>> DEBUG: Asset "assets/logocerta.png" parece estar carregável pelo AssetBundle.');
    } on FlutterError catch (e) {
      print(
          '>>> DEBUG: ERRO Flutter ao carregar asset "assets/logocerta.png" pelo AssetBundle: $e');
      print(
          '>>> DEBUG: Verifique se o nome do arquivo está EXATO (case-sensitive) e se o pubspec.yaml está correto na seção assets.');
    } catch (e) {
      print(
          '>>> DEBUG: ERRO geral ao verificar asset "assets/logocerta.png": $e');
    }
  }
  // FIM DO MÉTODO DE DEPURACAO PARA O ASSET DA LOGO

  // Método para buscar as transações do Supabase
  Future<void> _fetchTransactions() async {
    print('>>> _fetchTransactions() iniciado.');
    setState(() {
      _isLoading = true;
    });

    try {
      // Obter o ID do usuário logado
      final User? user = supabase.auth.currentUser;
      if (user == null) {
        print('Nenhum usuário logado. Não é possível buscar transações.');
        setState(() {
          _isLoading = false;
          _transactions = []; // Limpa as transações se não houver usuário logado
        });
        // Idealmente, este widget só é acessível se o usuário estiver logado.
        // O redirecionamento na MyApp já cuidará disso.
        return;
      }

      final List<Map<String, dynamic>> response = await supabase
          .from('transactions')
          .select('*')
          .eq('user_id', user.id)
          .order('date', ascending: false);

      print('>>> Resposta bruta do Supabase: $response'); // Manter para debug

      setState(() {
        _transactions =
            response.map((json) => Transaction.fromJson(json)).toList();
        _isLoading = false;
        print(
            '>>> Transações fetched e _transactions atualizado. Total: ${_transactions.length}');
        print(
            '>>> Saldo Atual Calculado: R\$ ${_currentBalance.toStringAsFixed(2)}');
        print(
            '>>> Receitas Mês Calculado: R\$ ${_monthlyIncome.toStringAsFixed(2)}');
        print(
            '>>> Despesas Mês Calculado: R\$ ${_monthlyExpense.toStringAsFixed(2)}');
      });
    } on PostgrestException catch (e) {
      print('>>> ERRO Postgrest ao buscar transações: ${e.message}');
      setState(() {
        _isLoading = false;
      });
      if (mounted) { // Verifica se o widget ainda está montado antes de mostrar o SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar transações: ${e.message}')),
        );
      }
    } catch (error) {
      print('>>> ERRO geral ao buscar transações: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) { // Verifica se o widget ainda está montado antes de mostrar o SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar transações: $error')),
        );
      }
    }
    print('>>> _fetchTransactions() finalizado.');
  }

  double get _currentBalance {
    final totalIncome = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.value);
    final totalExpense = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.value);
    return totalIncome - totalExpense;
  }

  // FUNÇÃO PARA CALCULAR O TOTAL DE TODAS AS RECEITAS
  double get _monthlyIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.value);
  }

  // FUNÇÃO PARA CALCULAR O TOTAL DE TODAS AS DESPESAS
  double get _monthlyExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.value);
  }

  // FUNÇÃO PARA EXCLUIR TRANSAÇÕES CADASTRADAS
  Future<void> _deleteTransactionFromList(String transactionId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir esta transação?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        print('>>> Tentando excluir transação com ID: $transactionId');
        await supabase
            .from('transactions')
            .delete()
            .eq('id', transactionId); // Usa o ID da transação passada

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transação excluída com sucesso!')),
          );
        }
        _fetchTransactions(); // Recarrega a lista após a exclusão
      } catch (error) {
        print('Erro de exclusão Supabase (direto da lista): $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir transação: $error')),
          );
        }
      }
    }
  }
  //FIM DA FUNÇÃO PARA EXCLUIR TRANSAÇÕES CADASTRADAS

  // FUNÇÃO PARA FAZER LOGOUT
  Future<void> _logout() async {
    setState(() {
      _isLoading = true; // Opcional, para mostrar um loading durante o logout
    });
    try {
      await _authService.signOut();
      // O listener em MyApp já tratará o redirecionamento para a página de login.
    } catch (e) {
      print('Erro ao fazer logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer logout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  //FIM FA FUNÇÃO PARA FAZER LOGOUT

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 80.0,
        title: Center(
          // Centraliza o conteúdo da Row
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Centraliza os itens dentro da Row
            children: [
              Image.asset(
                'assets/logocerta.png',
                height: 250,
                width: 300,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        // ÍCONES DA APP BAR
        actions: [
          IconButton(
            icon: Icon(
              _areNumbersVisible ? Icons.visibility : Icons.visibility_off,
              size: 30.0,
            ),
            onPressed: () {
              setState(() {
                _areNumbersVisible = !_areNumbersVisible; // Inverte o valor
              });
            },
            tooltip: _areNumbersVisible ? 'Ocultar Valores' : 'Mostrar Valores',
          ),
          // Local para mais ícones
        ],
      ),
      // FIM DA APP BAR

      // INÍCIO DO DRAWER - MENU LATERAL
      drawer: Drawer(
        child: Column( // Use Column para empilhar o cabeçalho, a lista de itens e o item fixo de logout
          children: <Widget>[
            // Cabeçalho do Drawer (DrawerHeader)
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 172, 224, 207), // Cor de fundo do cabeçalho
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0), // Cor do texto no cabeçalho
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Área expansível para os itens do menu (Página do Usuário, etc.)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero, // Mantenha isso para evitar padding extra no ListView
                children: <Widget>[
                  // Item: Página do Usuário
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Página do Usuário'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            // INÍCIO DO ÍCONE DE LOGOUT
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer antes de fazer logout
                _logout(); // Chama a função de logout
              },
            ),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
      // FIM DO DRAWER - MENU LATERAL

      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                "Visão Geral",
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge,
              ),
            ),

            // INÍCIO DA ROW DOS CARDS
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Padding ajustado para 3 cards
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Saldo Atual',
                              style: TextStyle(
                                fontSize: 14, // Fonte ajustada para 3 cards
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4), // Espaçamento ajustado
                            Text(
                              _areNumbersVisible
                                  ? 'R\$ ${_currentBalance.toStringAsFixed(2)}' // Exibe o valor
                                  : '*****', // Oculta o valor
                              style: const TextStyle(
                                fontSize: 18, // Fonte ajustada
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Espaçamento entre os cards
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Receitas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _areNumbersVisible
                                  ? 'R\$ ${_monthlyIncome.toStringAsFixed(2)}' // Exibe o valor
                                  : '*****', // Oculta o valor
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Espaçamento entre os cards
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0), // Padding ajustado
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Despesas', // Texto mais curto
                              style: TextStyle(
                                fontSize: 14, // Fonte ajustada
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4), // Espaçamento ajustado
                            Text(
                              _areNumbersVisible
                                  ? 'R\$ ${_monthlyExpense.toStringAsFixed(2)}' // Exibe o valor
                                  : '*****', // Oculta o valor,
                              style: const TextStyle(
                                fontSize: 18, // Fonte ajustada
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // FIM DA ROW DOS CARDS

            // INÍCIO DA ROW DOS BOTÕES ADICIONAR RECEITA E DESPESA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        print('Navegando para AddIncomeScreen...');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddIncomeScreen(),
                          ),
                        ).then((_) {
                          print(
                              'Retornou de AddIncomeScreen. Chamando _fetchTransactions()...');
                          _fetchTransactions();
                        });
                      },
                      child: const Text('Adicionar Receita'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        print('Navegando para AddExpenseScreen...');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddExpenseScreen(),
                          ),
                        ).then((_) {
                          print(
                              'Retornou de AddExpenseScreen. Chamando _fetchTransactions()...');
                          _fetchTransactions();
                        });
                      },
                      child: const Text('Adicionar Despesa'),
                    ),
                  ),
                ],
              ),
            ),
            // FIM DA ROW DOS BOTÕES ADICIONAR RECEITA E DESPESA

            // INÍCIO DO BOTÃO VER RELATÓRIO
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: ElevatedButton(
                onPressed: () async {
                  print('Ver Relatórios Clicando!');
                  if (_transactions.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Não há transações para gerar o relatório.')),
                      );
                    }
                    return;
                  }
                  try {
                    // Gera o PDF
                    final pdfBytes =
                        await PdfReportGenerator.generateTransactionReport(
                            _transactions);

                    // Abre o visualizador de PDF (ou a opção de compartilhar/imprimir)
                    await Printing.layoutPdf(
                        onLayout: (PdfPageFormat format) async => pdfBytes);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Relatório PDF gerado com sucesso!')),
                      );
                    }
                  } catch (e) {
                    print('ERRO ao gerar/visualizar PDF: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Erro ao gerar relatório PDF: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  // Cores do botão
                  backgroundColor: const Color(
                      0xFF025928), // Cor de fundo do botão (ex: roxo)
                  foregroundColor: Colors
                      .white, // Cor do texto e ícones do botão (ex: branco)

                  // Opcional: Ajuste de padding ou tamanho mínimo
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15), // Padding interno
                  minimumSize:
                      const Size(200, 50), // Tamanho mínimo (largura, altura)

                  // Opcional: Bordas arredondadas
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(40), // Bordas arredondadas
                  ),
                  // Opcional: Elevação da sombra
                  elevation: 5,
                ),
                child: const Text(
                  'Ver Relatórios',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold), // <--- Opcional: Estilo do texto
                ),
              ),
            ),
            // FIM DO BOTÃO VER RELATÓRIO

            // INÍCIO DA LISTA DO BALANÇO CADASTRADO PELO USUÁRIO
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                "Últimas Transações",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma transação encontrada. Adicione uma nova!',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      transaction.type == TransactionType.income
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                  child: Icon(
                                    transaction.type == TransactionType.income
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: transaction.type ==
                                            TransactionType.income
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  transaction.description,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(transaction.date),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      // Visibilidade de números (seu código já tem isso)
                                      _areNumbersVisible
                                          ? 'R\$ ${transaction.value.toStringAsFixed(2)}'
                                          : 'R\$ *****.**',
                                      style: TextStyle(
                                        color: transaction.type ==
                                                TransactionType.income
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 32.0),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20.0),
                                      color: Colors.grey[600],
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TransactionDetailScreen(
                                                    transaction: transaction),
                                          ),
                                        );
                                        if (result == true) {
                                          _fetchTransactions();
                                        }
                                      },
                                      tooltip: 'Editar Transação',
                                    ),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.delete, size: 20.0),
                                      color: Colors.red[400],
                                      onPressed: () {
                                        _deleteTransactionFromList(
                                            transaction.id);
                                      },
                                      tooltip: 'Excluir Transação',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            // FIM DA LISTA DO BALANÇO CADASTRADO PELO USUÁRIO
          ],
        ),
      ),
    );
  }
}