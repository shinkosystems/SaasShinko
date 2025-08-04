// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:saas_gestao_financeira/pages/login_page.dart';
import 'package:saas_gestao_financeira/pages/signup_page.dart';
import 'package:saas_gestao_financeira/services/auth_service.dart';
import 'package:saas_gestao_financeira/add_income_screen.dart';
import 'package:saas_gestao_financeira/add_expense_screen.dart';
import 'package:saas_gestao_financeira/transaction_model.dart';
import 'package:saas_gestao_financeira/transaction_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:saas_gestao_financeira/pages/user_page.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:saas_gestao_financeira/pdf_report_generator.dart';
import 'package:supabase/supabase.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        print('MyApp: Evento Signed In detectado. Redirecionando para Home.');
        if (navigatorKey.currentState != null &&
            navigatorKey.currentContext != null) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      } else if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.initialSession) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          print(
              'MyApp: Evento Signed Out/Initial Session (sem usuário). Redirecionando para Login.');
          if (navigatorKey.currentState != null &&
              navigatorKey.currentContext != null) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SaaS Gestão Financeira',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 172, 224, 207),
        ),
        useMaterial3: true,
      ),
      // Defina as rotas nomeadas
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (navigatorKey.currentState != null &&
          navigatorKey.currentContext != null) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
      }
    } else {
      if (navigatorKey.currentState != null &&
          navigatorKey.currentContext != null) {
        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Antiga MyHomePage, agora renomeada para HomePage
class HomePage extends StatefulWidget {
  const HomePage(
      {super.key}); // Removido 'required this.title' pois o título pode vir do drawer ou ser estático na AppBar.

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _areNumbersVisible = true;

  final SupabaseClient supabase = Supabase.instance.client;
  final AuthService _authService =
      AuthService(); // Instância do serviço de autenticação para logout

  @override
  void initState() {
    super.initState();
    _checkAssetExistence();
    _fetchTransactions(); // Inicia o carregamento das transações ao iniciar a tela
  }

  // MÉTODO DE DEPURACAO PARA O ASSET DA LOGO
  Future<void> _checkAssetExistence() async {
    try {
      await DefaultAssetBundle.of(context).load('assets/logocerta.png');
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

  Future<void> _fetchTransactions() async {
    print('>>> _fetchTransactions() iniciado.');
    if (!mounted) {
      // ADIÇÃO DA VERIFICAÇÃO DE mounted
      print(
          '>>> _fetchTransactions(): Widget não está montado, abortando setState().');
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      // Adicione um filtro para buscar transações apenas do usuário logado
      final User? user = supabase.auth.currentUser;
      if (user == null) {
        print('Nenhum usuário logado. Não é possível buscar transações.');
        if (mounted) {
          // ADIÇÃO DA VERIFICAÇÃO DE mounted
          setState(() {
            _isLoading = false;
            _transactions =
                []; // Limpa as transações se não houver usuário logado
          });
        }
        // O ideal é que este widget só seja acessado se o usuário estiver logado.
        // O redirecionamento na MyApp já cuidará disso.
        return;
      }

      final List<Map<String, dynamic>> response = await supabase
          .from('transactions')
          .select('*')
          .eq('user_id',
              user.id) // FILTRO ESSENCIAL: busca transações do user_id atual
          .order('date', ascending: false);

      print('>>> Resposta bruta do Supabase: $response');

      if (mounted) {
        // ADIÇÃO DA VERIFICAÇÃO DE mounted
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
      }
    } on PostgrestException catch (e) {
      print('>>> ERRO Postgrest ao buscar transações: ${e.message}');
      if (mounted) {
        // ADIÇÃO DA VERIFICAÇÃO DE mounted
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar transações: ${e.message}')),
        );
      }
    } catch (error) {
      print('>>> ERRO geral ao buscar transações: $error');
      if (mounted) {
        // ADIÇÃO DA VERIFICAÇÃO DE mounted
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
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

  double get _monthlyIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.value);
  }

  double get _monthlyExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.value);
  }

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
        await supabase.from('transactions').delete().eq('id', transactionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transação excluída com sucesso!')),
          );
        }
        _fetchTransactions();
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

  Future<void> _logout() async {
    if (!mounted) return; // ADIÇÃO DA VERIFICAÇÃO DE mounted
    setState(() {
      _isLoading = true; // Opcional, para mostrar um loading durante o logout
    });
    try {
      await _authService.signOut();
      // O listener em MyApp já tratará o redirecionamento.
    } catch (e) {
      print('Erro ao fazer logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer logout: $e')),
        );
      }
    } finally {
      if (mounted) {
        // ADIÇÃO DA VERIFICAÇÃO DE mounted
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 80.0,
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
        actions: [
          IconButton(
            icon: Icon(
              _areNumbersVisible ? Icons.visibility : Icons.visibility_off,
              size: 30.0,
            ),
            onPressed: () {
              if (mounted) {
                // ADIÇÃO DA VERIFICAÇÃO DE mounted
                setState(() {
                  _areNumbersVisible = !_areNumbersVisible;
                });
              }
            },
            tooltip: _areNumbersVisible ? 'Ocultar Valores' : 'Mostrar Valores',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 172, 224, 207),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Página do Usuário'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                _logout(); // Chama a função de logout
              },
            ),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
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
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Saldo Atual',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _areNumbersVisible
                                  ? 'R\$ ${_currentBalance.toStringAsFixed(2)}'
                                  : '*****',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                                  ? 'R\$ ${_monthlyIncome.toStringAsFixed(2)}'
                                  : '*****',
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Despesas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _areNumbersVisible
                                  ? 'R\$ ${_monthlyExpense.toStringAsFixed(2)}'
                                  : '*****',
                              style: const TextStyle(
                                fontSize: 18,
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
                    final pdfBytes =
                        await PdfReportGenerator.generateTransactionReport(
                            _transactions);

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
                  backgroundColor: const Color(0xFF025928),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Ver Relatórios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
                        physics: const NeverScrollableScrollPhysics(),
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
          ],
        ),
      ),
    );
  }
}
