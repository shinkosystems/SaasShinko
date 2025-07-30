import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira/add_income_screen.dart';
import 'package:saas_gestao_financeira/add_expense_screen.dart';
import 'package:saas_gestao_financeira/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mantenha suas chaves Supabase aqui
const SUPABASE_URL = 'https://rquhueanhjdozuhielag.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxdWh1ZWFuaGpkb3p1aGllbGFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3MjQ2MzMsImV4cCI6MjA2OTMwMDYzM30.kXkdpa6I7KnknyyAvdu1up2DEHyBC1-hy9BaYgKag4k';

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
          seedColor: const Color.fromARGB(255, 40, 157, 253),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Página Inicial - SaaS Gestão Financeira',
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

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchTransactions(); // Inicia o carregamento das transações ao iniciar a tela
  }

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
        _transactions = response.map((json) => Transaction.fromJson(json)).toList();
        _isLoading = false;
        print('>>> Transações fetched e _transactions atualizado. Total: ${_transactions.length}');
        print('>>> Saldo Atual Calculado: R\$ ${_currentBalance.toStringAsFixed(2)}');
        print('>>> Receitas Mês Calculado: R\$ ${_monthlyIncome.toStringAsFixed(2)}');
        print('>>> Despesas Mês Calculado: R\$ ${_monthlyExpense.toStringAsFixed(2)}');
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

  double get _monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.value);
  }

  double get _monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView( // Mantendo o SingleChildScrollView para a página toda
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
              child: Row( // Uma única Row para os três cards
                children: <Widget>[
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0), // Padding ajustado para 3 cards
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
                              'R\$ ${_currentBalance.toStringAsFixed(2)}',
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
                        padding: const EdgeInsets.all(8.0), // Padding ajustado
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Receitas', // Texto mais curto
                              style: TextStyle(
                                fontSize: 14, // Fonte ajustada
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4), // Espaçamento ajustado
                            Text(
                              'R\$ ${_monthlyIncome.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18, // Fonte ajustada
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
                  Expanded( // Terceiro card na mesma Row
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
                              'R\$ ${_monthlyExpense.toStringAsFixed(2)}',
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

            // INÍCIO DA ROW DOS BOTÕES RECEITA E DESPESA
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
                          print('Retornou de AddIncomeScreen. Chamando _fetchTransactions()...');
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
                          print('Retornou de AddExpenseScreen. Chamando _fetchTransactions()...');
                          _fetchTransactions();
                        });
                      },
                      child: const Text('Adicionar Despesa'),
                  ),
                  ),
                ],
              ),
            ),
            // FIM DA ROW DOS BOTÕES RECEITA E DESPESA

            // INÍCIO DO BOTÃO VER RELATÓRIO
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: TextButton(
                onPressed: () {
                  print('Ver Relatórios Clicando!');
                },
                child: const Text('Ver Relatórios'),
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
                    : SizedBox(
                        height: 100, // AJUSTE DE ALTURA DA LISTA DE TRANSAÇÕES
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 2,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  leading: CircleAvatar(
                                    backgroundColor: transaction.type == TransactionType.income
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    child: Icon(
                                      transaction.type == TransactionType.income
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      color: transaction.type == TransactionType.income
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    transaction.description,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.year}',
                                  ),
                                  trailing: Text(
                                    'R\$ ${transaction.value.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: transaction.type == TransactionType.income
                                        ? Colors.green
                                        : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Botão Flutuante Clicando!');
        },
        tooltip: 'Nova Transação',
        child: const Icon(Icons.add),
      ),
    );
  }
}