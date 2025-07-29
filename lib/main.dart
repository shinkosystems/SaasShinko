import 'package:flutter/material.dart';
import 'package:saas_gestao_financeira/add_income_screen.dart';
import 'package:saas_gestao_financeira/add_expense_screen.dart';
import 'package:saas_gestao_financeira/transaction_model.dart';

void main() {
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
      title: 'SaaS Gestão Financeira', // Altere o título do app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 40, 157, 253),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Página Inicial - SaaS Gestão Financeira',
      ), // Altere o título da página inicial
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
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      description: 'Salário de Julho',
      value: 3000.00,
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: TransactionType.income,
    ),
    Transaction(
      id: '2',
      description: 'Aluguel',
      value: 1200.00,
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: TransactionType.expense,
    ),
    Transaction(
      id: '3',
      description: 'Venda de Item Antigo',
      value: 250.00,
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.income,
    ),
    Transaction(
      id: '4',
      description: 'Supermercado',
      value: 350.50,
      date: DateTime.now(),
      type: TransactionType.expense,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                "Ações Rápidas",
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge, // Estilo de texto grande
              ),
            ),
            Padding(
              //Início dos Cards
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Saldo Atual',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'R\$ 1.500,00',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Espaço entre os cards
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Receitas (Mês)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'R\$ 2.000,00',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
              //Início card #2
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Despesas (Mês)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'R\$ 500,00',
                              style: TextStyle(
                                fontSize: 24,
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
            ), //Final dos cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      // <--- BOTÃO ADICIONAR RECEITAS
                      onPressed: () {
                        Navigator.push(
                          // <--- Começamos a navegação aqui!
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AddIncomeScreen(), // <--- Vai para a nova tela
                          ),
                        );
                      },
                      child: const Text('Adicionar Receita'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      // <--- BOTÃO ADICIONAR DESPESA
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AddExpenseScreen(), // <--- Vai para a nova tela
                          ),
                        );
                      },
                      child: const Text('Adicionar Despesa'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: TextButton(
                // <--- BOTÃO VER RELATÓRIOS
                onPressed: () {
                  print('Ver Relatórios Clicando!');
                },
                child: const Text('Ver Relatórios'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                "Últimas Transações",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            // Aqui virá a lista de transações
            // Usaremos um ListView.builder dentro de um Expanded ou SizedBox para dar limite de altura
            SizedBox(
              // Usamos SizedBox para dar uma altura fixa para a lista no momento
              height:
                  300, // Ajuste a altura conforme necessário para ver os itens
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  return Card(
                    // Para cada transação, um Card simples por enquanto
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: ListTile(
                      leading: Icon(
                        transaction.type == TransactionType.income
                            ? Icons
                                  .arrow_upward // Ícone para receita
                            : Icons.arrow_downward, // Ícone para despesa
                        color: transaction.type == TransactionType.income
                            ? Colors
                                  .green // Cor verde para receita
                            : Colors.red, // Cor vermelha para despesa
                      ),
                      title: Text(transaction.description),
                      subtitle: Text(
                        '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                      ),
                      trailing: Text(
                        'R\$ ${transaction.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transaction.type == TransactionType.income
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ), // Se quiser adicionar mais coisas, adicione aqui dentro da Column
          ],
        ),
      ), // <--- Fechamento CORRETO do SingleChildScrollView
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Botão Flutuante Clicando!'); // Nova ação para o FAB
        },
        tooltip: 'Nova Transação', // Novo tooltip
        child: const Icon(Icons.add),
      ),
    );
  }
}
