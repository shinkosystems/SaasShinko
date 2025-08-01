import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira/add_income_screen.dart';
import 'package:saas_gestao_financeira/add_expense_screen.dart';
import 'package:saas_gestao_financeira/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saas_gestao_financeira/transaction_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:saas_gestao_financeira/user_page.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:saas_gestao_financeira/pdf_report_generator.dart';

// Mantenha suas chaves Supabase aqui
const SUPABASE_URL = 'https://rquhueanhjdozuhielag.supabase.co';
const SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxdWh1ZWFuaGpkb3p1aGllbGFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3MjQ2MzMsImV4cCI6MjA2OTMwMDYzM30.kXkdpa6I7KnknyyAvdu1up2DEHyBC1-hy9BaYgKag4k';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaaS Gestão Financeira',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 172, 224, 207),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Shinko - Gestão Financeira',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _areNumbersVisible = true;

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkAssetExistence(); // <--- Chamada para a função de depuração da logo
    _fetchTransactions(); // Inicia o carregamento das transações ao iniciar a tela
  }

  // MÉTODO DE DEPURACAO PARA O ASSET DA LOGO
  Future<void> _checkAssetExistence() async {
    try {
      // Tenta carregar o asset diretamente pelo AssetBundle
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
      final List<Map<String, dynamic>> response = await supabase
          .from('transactions')
          .select('*')
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar transações: ${e.message}')),
      );
    } catch (error) {
      print('>>> ERRO geral ao buscar transações: $error');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar transações: $error')),
      );
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
        final response = await supabase
            .from('transactions')
            .delete()
            .eq('id', transactionId); // Usa o ID da transação passada

        print('>>> Resposta do Supabase após delete: $response');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação excluída com sucesso!')),
        );
        _fetchTransactions(); // Recarrega a lista após a exclusão
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir transação: $error')),
        );
        print('Erro de exclusão Supabase (direto da lista): $error');
      }
    }
  }
  //FIM DA FUNÇÃO PARA EXCLUIR TRANSAÇÕES CADASTRADAS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 80.0, // Mantenha ou ajuste a altura total da AppBar
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
                color: const Color.fromARGB(255, 172, 224, 207), // Cor de fundo do cabeçalho
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
                // Exemplo de navegação:
                // Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen()));
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
          Navigator.pop(context);
          // *** Lógica para logout ***
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lógica de Logout a ser implementada!')),
          );
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Não há transações para gerar o relatório.')),
                    );
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

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Relatório PDF gerado com sucesso!')),
                    );
                  } catch (e) {
                    print('ERRO ao gerar/visualizar PDF: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Erro ao gerar relatório PDF: $e')),
                    );
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
