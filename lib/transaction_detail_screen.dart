import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:saas_gestao_financeira/models/transaction_model.dart';
import 'package:saas_gestao_financeira/ad_banner.dart';
import 'package:saas_gestao_financeira/ad_interstitial.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({Key? key, required this.transaction})
      : super(key: key);

  @override
  _TransactionDetailScreenState createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;

  late TextEditingController _descriptionController;
  late TextEditingController _valueController;
  late TransactionType _selectedType;
  late DateTime _selectedDate;

  final AdInterstitial _adManager = AdInterstitial();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );
    _valueController = TextEditingController(
      text: widget.transaction.value.toStringAsFixed(2),
    );
    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;
    _adManager.loadAd();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _onAdClosedAndNavigate() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação atualizada com sucesso!')),
      );
      Navigator.pop(
        context,
        true,
      );
    }
  }

  Future<void> _updateTransaction() async {
    if (_formKey.currentState!.validate()) {
      try {
        final User? user = supabase.auth.currentUser;
        if (user == null) {
          print('Nenhum usuário logado. Não é possível atualizar a transação.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro: Usuário não logado.')),
            );
            Navigator.pop(context, false);
          }
          return;
        }

        await supabase
            .from('transactions')
            .update({
              'description': _descriptionController.text,
              'value': double.parse(
                _valueController.text.replaceAll(',', '.'),
              ),
              'type': _selectedType.toString().split('.').last,
              'date': _selectedDate.toIso8601String(),
            })
            .eq(
              'id',
              widget.transaction.id,
            )
            .eq(
              'user_id',
              user.id,
            );

        _adManager.showAd(onAdDismissed: _onAdClosedAndNavigate);
      } on PostgrestException catch (e) {
        print('Erro ao atualizar transação no Supabase: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar transação: ${e.message}'),
            ),
          );
        }
      } catch (error) {
        print('Erro inesperado ao atualizar transação: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro inesperado ao atualizar transação.')),
          );
        }
      }
    }
  }

  Future<void> _deleteTransaction() async {
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
        final User? user = supabase.auth.currentUser;
        if (user == null) {
          print('Nenhum usuário logado. Não é possível excluir a transação.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro: Usuário não logado.')),
            );
            Navigator.pop(context, false);
          }
          return;
        }

        await supabase
            .from('transactions')
            .delete()
            .eq(
              'id',
              widget.transaction.id,
            )
            .eq(
              'user_id',
              user.id,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transação excluída com sucesso!')),
          );
          Navigator.pop(
            context,
            true,
          );
        }
      } on PostgrestException catch (e) {
        print('Erro ao excluir transação no Supabase: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir transação: ${e.message}')),
          );
        }
      } catch (error) {
        print('Erro inesperado ao excluir transação: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro inesperado ao excluir transação.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Transação'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTransaction,
            tooltip: 'Excluir Transação',
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Valor',
                      border: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixText: ' R\$ ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um valor.';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'Por favor, insira um número válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      border: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      hintText: ' Ex: Salário, Aluguel, Compras',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira uma descrição.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TransactionType>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      border: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TransactionType.income,
                        child: Text(' Receita'),
                      ),
                      DropdownMenuItem(
                        value: TransactionType.expense,
                        child: Text(' Despesa'),
                      ),
                    ],
                    onChanged: (TransactionType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedType = newValue;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecione um tipo.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Data da Transação'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const Divider(
                    height: 20,
                    thickness: 2,
                    color: Colors.grey,
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _updateTransaction,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Salvar Alterações'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(child: AdBanner()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}