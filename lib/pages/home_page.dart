import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:saas_gestao_financeira_backup/models/transaction_model.dart';
import 'package:saas_gestao_financeira_backup/pages/login_page.dart';
import 'package:saas_gestao_financeira_backup/pages/user_page.dart';
import 'package:saas_gestao_financeira_backup/add_income_screen.dart';
import 'package:saas_gestao_financeira_backup/add_expense_screen.dart';
import 'package:saas_gestao_financeira_backup/pdf_report_generator.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:saas_gestao_financeira_backup/transaction_detail_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  final String userId = Supabase.instance.client.auth.currentUser!.id;
  bool _isMoneyVisible = true;
  String? _userName;

  DateTime? _startDate;
  DateTime? _endDate;

  // Variável de estado para controlar a ordem de ordenação
  // Inicia como false, que corresponde à ordem decrescente (mais recente primeiro)
  bool _isSortedAscending = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchUserName();
    await _fetchTransactions();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserName() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _userName = response['username'] as String?;
          print('Nome do usuário buscado: $_userName');
        });
      }
    } catch (e) {
      if (mounted) {
        print('Erro ao buscar nome do usuário: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao buscar o nome do usuário.')),
        );
      }
    }
  }

  Future<void> _fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    setState(() {
      _isLoading = true;
    });
    try {
      var query = supabase.from('transactions').select().eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        final nextDay = endDate.add(const Duration(days: 1));
        query = query.lt('date', nextDay.toIso8601String());
      }
      
      final response = await query.order('date', ascending: _isSortedAscending);

      if (mounted) {
        setState(() {
          _transactions = (response as List<dynamic>)
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList();

          _totalIncome = 0;
          _totalExpense = 0;
          for (var transaction in _transactions) {
            if (transaction.type == TransactionType.income) {
              _totalIncome += transaction.value;
            } else if (transaction.type == TransactionType.expense) {
              _totalExpense += transaction.value;
            }
          }
          _balance = _totalIncome - _totalExpense;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _toggleSortOrder() {
    setState(() {
      _isSortedAscending = !_isSortedAscending;
    });
    _fetchTransactions(startDate: _startDate, endDate: _endDate);
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (isStartDate) {
        if (_endDate != null && picked.isAfter(_endDate!)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('A data inicial não pode ser depois da data final.'),
              ),
            );
          }
          return;
        }
        setState(() {
          _startDate = picked;
        });
      } else {
        if (_startDate != null && picked.isBefore(_startDate!)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('A data final não pode ser antes da data inicial.'),
              ),
            );
          }
          return;
        }
        setState(() {
          _endDate = picked;
        });
      }
      _fetchTransactions(startDate: _startDate, endDate: _endDate);
    }
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchTransactions(); // Busca todas as transações novamente
  }

  void _addIncome() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddIncomeScreen()))
        .then((value) {
      if (value == true) {
        _fetchTransactions(startDate: _startDate, endDate: _endDate);
      }
    });
  }

  void _addExpense() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddExpenseScreen()))
        .then((value) {
      if (value == true) {
        _fetchTransactions(startDate: _startDate, endDate: _endDate);
      }
    });
  }

  void _editTransaction(Transaction transaction) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                TransactionDetailScreen(transaction: transaction),
          ),
        )
        .then((shouldRefresh) {
          if (shouldRefresh == true) {
            _fetchTransactions(startDate: _startDate, endDate: _endDate);
          }
        });
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(amount);
  }

  void _toggleMoneyVisibility() {
    setState(() {
      _isMoneyVisible = !_isMoneyVisible;
    });
  }

  Future<bool> _showDeleteConfirmationDialog() async {
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
    return confirm ?? false;
  }

  void _performDeleteTransaction(Transaction transaction) async {
    try {
      await supabase
          .from('transactions')
          .delete()
          .eq('id', transaction.id)
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação excluída com sucesso!')),
        );
        _fetchTransactions(startDate: _startDate, endDate: _endDate);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir transação: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 80.0,
        centerTitle: true,
        title: Image.asset(
          'assets/logocerta.png',
          height: 250,
          width: 300,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isMoneyVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: _toggleMoneyVisibility,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
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
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Página do Usuário'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const UserPage()),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                await supabase.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Que bom te ver por aqui, ${_userName ?? '[username]'}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        const Center(
                          child: Text(
                            'Visão Geral',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        _buildAddButtons(),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              print('Ver Relatórios Clicando!');
                              if (_transactions.isEmpty) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Não há transações para gerar o relatório.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              try {
                                final pdfBytes =
                                    await PdfReportGenerator.generateTransactionReport(
                                  _transactions,
                                );

                                await Printing.layoutPdf(
                                  onLayout: (PdfPageFormat format) async =>
                                      pdfBytes,
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Relatório PDF gerado com sucesso!',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('ERRO ao gerar/visualizar PDF: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao gerar relatório PDF: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF025928),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              minimumSize: const Size(200, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Ver Relatórios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const Center(
                          child: Text(
                            'Transações Cadastradas',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Ordenar por período:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: () =>
                                      _selectDate(context, isStartDate: true),
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: Text(
                                    _startDate == null
                                        ? 'Data Inicial'
                                        : DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_startDate!),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _selectDate(context, isStartDate: false),
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: Text(
                                    _endDate == null
                                        ? 'Data Final'
                                        : DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_endDate!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_sweep_outlined,
                                    color: Color(0xFF2C735F),
                                  ),
                                  onPressed: _clearDateFilters,
                                  tooltip: 'Limpar Filtros de Data',
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                _isSortedAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                              ),
                              onPressed: _toggleSortOrder,
                              tooltip: _isSortedAscending
                                  ? 'Ordenar por mais recente'
                                  : 'Ordenar por mais antigo',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTransactionList(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(child: _buildSummaryCard('Saldo', _balance, Colors.blue, 14)),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard('Receitas', _totalIncome, Colors.green, 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard('Despesas', _totalExpense, Colors.red, 14),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    double titleFontSize,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: titleFontSize)),
            const SizedBox(height: 8),
            Text(
              _isMoneyVisible ? _formatCurrency(amount) : 'R\$ ******',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _addIncome,
            child: const Text('Adicionar Receita'),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 12, 100, 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: _addExpense,
            child: const Text('Adicionar Despesa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 12, 100, 4),
              side: const BorderSide(color: Color.fromARGB(255, 199, 199, 199)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('Nenhuma transação encontrada.'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];

        return Dismissible(
          key: Key(transaction.id),
          background: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              color: const Color.fromARGB(214, 211, 15, 15),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmationDialog();
          },
          onDismissed: (direction) {
            _performDeleteTransaction(transaction);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 8.0, right: 2.0),
              leading: CircleAvatar(
                radius: 18.0,
                backgroundColor: transaction.type == TransactionType.income ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  transaction.type == TransactionType.income ? Icons.arrow_upward : Icons.arrow_downward,
                  color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
                  size: 18.0,
                ),
              ),
              title: Text(
                transaction.description,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(transaction.date),
                style: const TextStyle(fontSize: 10),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isMoneyVisible
                        ? _formatCurrency(transaction.value)
                        : 'R\$ ******',
                    style: TextStyle(
                      color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
                      fontSize: 10,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Color.fromARGB(255, 102, 102, 102),
                    ),
                    onPressed: () => _editTransaction(transaction),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}